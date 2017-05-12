package POE::Component::IRC::Plugin::BotCommand;
BEGIN {
  $POE::Component::IRC::Plugin::BotCommand::AUTHORITY = 'cpan:HINRIK';
}
# vim: set expandtab ts=4 sw=4 ai:
$POE::Component::IRC::Plugin::BotCommand::VERSION = '6.88';
use strict;
use warnings FATAL => 'all';
use Carp;
use IRC::Utils qw( parse_user strip_color strip_formatting );
use POE::Component::IRC::Plugin qw( :ALL );

sub new {
    my ($package) = shift;
    croak "$package requires an even number of arguments" if @_ & 1;
    my %args = @_;

    $args{Method} = 'notice' if !defined $args{Method};

    for my $cmd (keys %{ $args{Commands} }) {
        if (ref $args{Commands}->{$cmd} eq 'HASH') {
            croak "$cmd: no info provided"
                if !exists $args{Commands}->{$cmd}->{info} ;
            $args{Commands}->{lc $cmd}->{handler} = 
                sprintf("irc_botcmd_%s", lc($cmd))
                if !$args{Commands}->{lc $cmd}->{handler};
        }
        $args{Commands}->{lc $cmd} = delete $args{Commands}->{$cmd};
    }
    return bless \%args, $package;
}

sub PCI_register {
    my ($self, $irc) = splice @_, 0, 2;

    $self->{Addressed}   = 1   if !defined $self->{Addressed};
    $self->{Prefix}      = '!' if !defined $self->{Prefix};
    $self->{In_channels} = 1   if !defined $self->{In_channels};
    $self->{In_private}  = 1   if !defined $self->{In_private};
    $self->{rx_cmd_args} = qr/^(\S+)(?:\s+(.+))?$/;
    $self->{irc} = $irc;

    $irc->plugin_register( $self, 'SERVER', qw(msg public) );
    return 1;
}

sub PCI_unregister {
    return 1;
}

sub S_msg {
    my ($self, $irc) = splice @_, 0, 2;
    my $who   = ${ $_[0] };
    my $where = parse_user($who);
    my $what  = ${ $_[2] };

    return PCI_EAT_NONE if !$self->{In_private};
    $what = $self->_normalize($what);

    if (!$self->{Bare_private}) {
        return PCI_EAT_NONE if $what !~ s/^\Q$self->{Prefix}\E//;
    }

    my ($cmd, $args);
    if (!(($cmd, $args) = $what =~ $self->{rx_cmd_args})) {
        return PCI_EAT_NONE;
    }

    $self->_handle_cmd($who, $where, $cmd, $args);
    return $self->{Eat} ? PCI_EAT_PLUGIN : PCI_EAT_NONE;
}

sub S_public {
    my ($self, $irc) = splice @_, 0, 2;
    my $who   = ${ $_[0] };
    my $where = ${ $_[1] }->[0];
    my $what  = ${ $_[2] };
    my $me    = $irc->nick_name();

    return PCI_EAT_NONE if !$self->{In_channels};
    $what = $self->_normalize($what);

    if ($self->{Addressed}) {
        return PCI_EAT_NONE if !(($what) = $what =~ m/^\s*\Q$me\E[:,;.!?~]?\s*(.*)$/);
    }
    else {
        return PCI_EAT_NONE if $what !~ s/^\Q$self->{Prefix}\E//;
    }

    my ($cmd, $args);
    if (!(($cmd, $args) = $what =~ $self->{rx_cmd_args})) {
        return PCI_EAT_NONE;
    }

    $self->_handle_cmd($who, $where, $cmd, $args);
    return $self->{Eat} ? PCI_EAT_PLUGIN : PCI_EAT_NONE;
}

sub _normalize {
    my ($self, $line) = @_;
    $line = strip_color($line);
    $line = strip_formatting($line);
    return $line;
}

sub _handle_cmd {
    my ($self, $who, $where, $cmd, $args) = @_;
    my $irc = $self->{irc};
    my $chantypes = join('', @{ $irc->isupport('CHANTYPES') || ['#', '&']});
    my $public = $where =~ /^[$chantypes]/ ? 1 : 0;
    $cmd = lc $cmd;

    my $cmd_unresolved = $cmd;

    if((my $cmd_resolved = $self->resolve_alias($cmd)))
    {
        $cmd = $cmd_resolved;
    }


    if (defined $self->{Commands}->{$cmd}) {
        if (ref $self->{Commands}->{$cmd} eq 'HASH') {
            my @args_array = defined $args ? split /\s+/, $args : ();
            if (defined($self->{Commands}->{$cmd}->{args}) &&
               ref($self->{Commands}->{$cmd}->{args}) eq 'ARRAY' &&
               @{ $self->{Commands}->{$cmd}->{args} } && 
               (@args_array < @{ $self->{Commands}->{$cmd}->{args} } ||
               (!defined $self->{Commands}->{$cmd}->{variable} &&
                @args_array > @{ $self->{Commands}->{$cmd}->{args} }))
            ) {
                  $irc->yield($self->{Method}, $where,
                      "Not enough or too many arguments. See help for $cmd");
                  return;
            }

            if(defined $self->{Commands}->{$cmd}->{variable} ||
                (defined($self->{Commands}->{$cmd}->{args}) &&
                    ref($self->{Commands}->{$cmd}->{args}) eq 'ARRAY' &&
                    @{ $self->{Commands}->{$cmd}->{args} }))
            {
                $args = {};
                if( defined($self->{Commands}->{$cmd}->{args}) &&
                    ref($self->{Commands}->{$cmd}->{args}) eq 'ARRAY' &&
                    @{ $self->{Commands}->{$cmd}->{args} })
                {
                    for (@{ $self->{Commands}->{$cmd}->{args} }) {
                        my $in_arg = shift @args_array;
                        if (ref $self->{Commands}->{$cmd}->{$_} eq 'ARRAY') {
                            my @values = @{ $self->{Commands}->{$cmd}->{$_} };
                            shift @values;

                            use List::MoreUtils qw(none);
                            # Check if argument has one of possible values
                            if (none { $_ eq $in_arg} @values) {
                                $irc->yield($self->{Method}, $where,
                                    "$_ can be one of ".join '|', @values);
                                return;
                            }

                        }
                        $args->{$_} = $in_arg;
                    }
                }

                # Process remaining arguments if variable is set
                my $arg_cnt = 0;
                if (defined $self->{Commands}->{$cmd}->{variable}) {
                    for (@args_array) {
                        $args->{"opt".$arg_cnt++} = $_;
                    }
                }
            }
        }
    }

    if (ref $self->{Auth_sub} eq 'CODE') {
        my ($authed, $errors) = $self->{Auth_sub}->($self->{irc}, $who, $where, $cmd, $args, $cmd_unresolved);

        if (!$authed) {
            my @errors = ref $errors eq 'ARRAY'
                ? @$errors
                : 'You are not authorized to use this command.';
            for my $error (@errors) {
                $irc->yield($self->{Method}, $where, $error);
            }
            return;
        }
    }

    if (defined $self->{Commands}->{$cmd}) {
        my $handler = (ref($self->{Commands}->{$cmd}) eq 'HASH' ? $self->{Commands}->{$cmd}->{handler} : "irc_botcmd_$cmd");
        $irc->send_event_next($handler => $who, $where, $args, $cmd, $cmd_unresolved);
    }
    elsif ($cmd =~ /^help$/i) {
        my @help = $self->_get_help($args, $public);
        $irc->yield($self->{Method} => $where => $_) for @help;
    }
    elsif (!$self->{Ignore_unknown}) {
        my @help = $self->_get_help($cmd, $public);
        $irc->yield($self->{Method} => $where => $_) for @help;
    }

    return;
}

sub _get_help {
    my ($self, $args, $public) = @_;
    my $irc = $self->{irc};
    my $p = $self->{Addressed} && $public
        ? $irc->nick_name().': '
        : $self->{Prefix};

    my @help;
    if (defined $args) {
        my $cmd = (split /\s+/, $args, 2)[0];

        $cmd = lc $cmd;

        my $cmd_resolved = $self->resolve_alias($cmd) || $cmd;

        if (exists $self->{Commands}->{$cmd_resolved}) {
            if (ref $self->{Commands}->{$cmd_resolved} eq 'HASH') {
                push @help, "Syntax: $p$cmd".
                    (   defined($self->{Commands}->{$cmd_resolved}->{args}) &&
                        ref($self->{Commands}->{$cmd_resolved}->{args}) eq 'ARRAY' ?
                        " ".join ' ', @{ $self->{Commands}->{$cmd_resolved}->{args} } :
                        "" ).
                    (defined $self->{Commands}->{$cmd_resolved}->{variable} ?
                        " ..."  : "");
                push @help, split /\015?\012/,
                    "Description: ".$self->{Commands}->{$cmd_resolved}->{info};
                if( defined($self->{Commands}->{$cmd_resolved}->{args}) &&
                    ref($self->{Commands}->{$cmd_resolved}->{args}) eq 'ARRAY' &&
                    @{ $self->{Commands}->{$cmd_resolved}->{args} })
                {
                    push @help, "Arguments:";

                    for my $arg (@{ $self->{Commands}->{$cmd_resolved}->{args} }) {
                        next if not defined $self->{Commands}->{$cmd_resolved}->{$arg};
                        if (ref $self->{Commands}->{$cmd_resolved}->{$arg} eq 'ARRAY') {
                            my @arg_usage = @{$self->{Commands}->{$cmd_resolved}->{$arg}};
                            push @help, "    $arg: ".$arg_usage[0].
                            " (".(join '|', @arg_usage[1..$#arg_usage]).")"
                        }
                        else {
                            push @help, "    $arg: ".
                                $self->{Commands}->{$cmd_resolved}->{$arg};
                        }
                    }
                }

                push @help, "Alias of: ${p}${cmd_resolved}" .
                        (ref($self->{Commands}->{$cmd_resolved}->{args}) eq 'ARRAY' ?
                        " ".join ' ', @{ $self->{Commands}->{$cmd_resolved}->{args} } :
                        "" ).
                    (defined $self->{Commands}->{$cmd_resolved}->{variable} ?
                        " ..."  : "")
                    if $cmd_resolved ne $cmd;

                my @aliases = grep { $_ ne $cmd } $self->list_aliases($cmd_resolved);

                if($cmd_resolved ne $cmd)
                {
                    push @aliases, $cmd_resolved;
                }

                push @help, "Aliases: ".join( " ", @aliases) if scalar(@aliases);
            }
            else {
                @help = split /\015?\012/, $self->{Commands}->{$cmd};
            }
        }
        else {
            push @help, "Unknown command: $cmd";
            push @help, "To get a list of commands, use: ${p}help";
        }
    }
    else {
        if (keys %{ $self->{Commands} }) {
            push @help, 'Commands: ' . join ', ', sort keys %{ $self->{Commands} };
            push @help, "For more details, use: ${p}help <command>";
        }
        else {
            push @help, 'No commands are defined';
        }
    }

    if(ref($self->{'Help_sub'}) eq 'CODE')
    {
        my ($cmd, $args) = (defined $args ? split /\s+/, $args, 2 : ('', ''));

        my $cmd_resolved = $self->resolve_alias($cmd) || $cmd;

        return $self->{'Help_sub'}->($self->{irc}, $cmd, $cmd_resolved, $args, @help);
    }
    else
    {
        return @help;
    }
}

sub add {
    my ($self, $cmd, $usage) = @_;
    $cmd = lc $cmd;
    return if exists $self->{Commands}->{$cmd};

    if (ref $usage eq 'HASH') {
        return if !exists $usage->{info} || !@{ $usage->{args} };
    }

    $self->{Commands}->{$cmd} = $usage;
    return 1;
}

sub remove {
    my ($self, $cmd) = @_;
    $cmd = lc $cmd;
    return if !exists $self->{Commands}->{$cmd};
    delete $self->{Commands}->{$cmd};
    return 1;
}

sub list {
    my ($self) = @_;
    return %{ $self->{Commands} };
}

sub resolve_alias {
    my ($self, $alias) = @_;
    
    my %cmds = $self->list();

    #TODO: refactor using smartmatch/Perl6::Junction if feasible
    while(my ($cmd, $info) = each(%cmds))
    {
       next unless ref($info) eq 'HASH';
       next unless $info->{aliases} && ref($info->{aliases}) eq 'ARRAY';
       my @aliases = @{$info->{aliases}};
       
       foreach my $cmdalias (@aliases)
       {
           return $cmd if $alias eq $cmdalias;
       }
    }

    return undef;
}

sub list_aliases
{
    my ($self, $cmd) = @_;
    $cmd = lc $cmd;
    return if !exists $self->{Commands}->{$cmd};
    return unless ref($self->{Commands}->{$cmd}) eq 'HASH';
    return unless exists $self->{Commands}->{$cmd}->{aliases} && ref($self->{Commands}->{$cmd}->{aliases}) eq 'ARRAY';
    return @{$self->{Commands}->{$cmd}->{aliases}};

}

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::BotCommand - A PoCo-IRC plugin which handles
commands issued to your bot

=head1 SYNOPSIS

 use POE;
 use POE::Component::Client::DNS;
 use POE::Component::IRC;
 use POE::Component::IRC::Plugin::BotCommand;

 my @channels = ('#channel1', '#channel2');
 my $dns = POE::Component::Client::DNS->spawn();
 my $irc = POE::Component::IRC->spawn(
     nick   => 'YourBot',
     server => 'some.irc.server',
 );

 POE::Session->create(
     package_states => [
         main => [ qw(_start irc_001 irc_botcmd_slap irc_botcmd_lookup dns_response) ],
     ],
 );

 $poe_kernel->run();

 sub _start {
     $irc->plugin_add('BotCommand', POE::Component::IRC::Plugin::BotCommand->new(
         Commands => {
             slap   => 'Takes one argument: a nickname to slap.',
             lookup => 'Takes two arguments: a record type (optional), and a host.',
         }
     ));
     $irc->yield(register => qw(001 botcmd_slap botcmd_lookup));
     $irc->yield(connect => { });
 }

 # join some channels
 sub irc_001 {
     $irc->yield(join => $_) for @channels;
     return;
 }

 # the good old slap
 sub irc_botcmd_slap {
     my $nick = (split /!/, $_[ARG0])[0];
     my ($where, $arg) = @_[ARG1, ARG2];
     $irc->yield(ctcp => $where, "ACTION slaps $arg");
     return;
 }

 # non-blocking dns lookup
 sub irc_botcmd_lookup {
     my $nick = (split /!/, $_[ARG0])[0];
     my ($where, $arg) = @_[ARG1, ARG2];
     my ($type, $host) = $arg =~ /^(?:(\w+) )?(\S+)/;

     my $res = $dns->resolve(
         event => 'dns_response',
         host => $host,
         type => $type,
         context => {
             where => $where,
             nick  => $nick,
         },
     );
     $poe_kernel->yield(dns_response => $res) if $res;
     return;
 }

 sub dns_response {
     my $res = $_[ARG0];
     my @answers = map { $_->rdatastr } $res->{response}->answer() if $res->{response};

     $irc->yield(
         'notice',
         $res->{context}->{where},
         $res->{context}->{nick} . (@answers
             ? ": @answers"
             : ': no answers for "' . $res->{host} . '"')
     );

     return;
 }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::BotCommand is a
L<POE::Component::IRC|POE::Component::IRC> plugin. It provides you with a
standard interface to define bot commands and lets you know when they are
issued. Commands are accepted as channel or private messages.

The plugin will respond to the 'help' command by default, listing available
commands and information on how to use them. However, if you add a help
command yourself, that one will be used instead.

=head1 METHODS

=head2 C<new>

B<'Commands'>, a hash reference, with your commands as keys, and usage
information as values. If the usage string contains newlines, the plugin
will send one message for each line.

If a command's value is a HASH ref like this:

     $irc->plugin_add('BotCommand', POE::Component::IRC::Plugin::BotCommand->new(
         Commands => {
             slap   => {
                info => 'Slap someone',
                args => [qw(nickname)],
                nickname => 'nickname to slap'
             }
         }
     ));

The args array reference is than used to validate number of arguments required
and to name arguments passed to event handler. Help is than generated from
C<info> and other hash keys which represent arguments (they are optional).

An optional C<handler> key can be specified inside the HASH ref to override the event handler.
The irc_botcmd_ prefix  is not automatically prepended  to the handler name when overriding it. 

An optional C<aliases>  key can be specified inside the HASH ref containing a array ref with alias names.
The aliases can be specified for help and to run the command.

=head3 Accepting commands

B<'In_channels'>, a boolean value indicating whether to accept commands in
channels. Default is true.

B<'In_private'>, a boolean value indicating whether to accept commands in
private. Default is true.

B<'Addressed'>, requires users to address the bot by name in order
to issue commands. Default is true.

B<'Prefix'>, a string which all commands must be prefixed with (except in
channels when B<'Addressed'> is true). Default is '!'. You can set it to ''
to allow bare commands.

B<'Bare_private'>, a boolean value indicating whether bare commands (without
the prefix) are allowed in private messages. Default is false.

=head3 Authorization

B<'Auth_sub'>, a subroutine reference which, if provided, will be called
for every command. The subroutine will be called in list context. If the
first value returned is true, the command will be processed as normal. If
the value is false, then no events will be generated, and an error message
will possibly be sent back to the user.

You can override the default error message by returning a second value, an
array reference of (zero or more) strings. Each string will be sent as a
message to the user.

Your subroutine will be called with the following arguments:

=over 4

=item 1. The IRC component object

=item 2. The nick!user@host of the user

=item 3. The place where the command was issued (the nickname of the user if
it was in private)

=item 4. The name of the command

=item 5. The command argument string

=back

B<'Ignore_unauthorized'>, if true, the plugin will ignore unauthorized
commands, rather than printing an error message upon receiving them. This is
only relevant if B<'Auth_sub'> is also supplied. Default is false.

=head3 Help Command

B<'Help_sub'>, a subroutine reference which, if provided, will be called upon
the end of the predefined help command. The subroutine will be called in list context.

Your subroutine will be called with the following arguments:

=over 4

=item 1. The IRC component object

=item 2. The command.

=item 3. The resolved command(after alias processing).

=item 4. The arguments.

=item 5. The generated help text as array.


=back


=head3 Miscellaneous

B<'Ignore_unknown'>, if true, the plugin will ignore undefined commands,
rather than printing a help message upon receiving them. Default is false.

B<'Method'>, how you want help messages to be delivered. Valid options are
'notice' (the default) and 'privmsg'.

B<'Eat'>, set to true to make the plugin hide
L<C<irc_public>|POE::Component::IRC/irc_public> events from other plugins
when they look like commands. Probably only useful when a B<'Prefix'> is
defined. Default is false.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add> method.

=head2 C<add>

Adds a new command. Takes two arguments, the name of the command, and a string
or hash reference containing its usage information (see C<new>). Returns false
if the command has already been defined or no info or arguments are provided,
true otherwise.

=head2 C<remove>

Removes a command. Takes one argument, the name of the command. Returns false
if the command wasn't defined to begin with, true otherwise.

=head2 C<list>

Takes no arguments. Returns a list of key/value pairs, the keys being the
command names and the values being the usage strings or hash references.

=head2 C<resolve_alias>

Takes one argument, a string to match against command aliases, if no matching
command can be found undef is returned.

=head1 OUTPUT EVENTS

=head2 C<irc_botcmd_*>

You will receive an event like this for every valid command issued. E.g. if
'slap' were a valid command, you would receive an C<irc_botcmd_slap> event
every time someone issued that command. It receives the following arguments:

=over 4

=item * C<ARG0>: the nick!hostmask of the user who issued the command.

=item * C<ARG1> is the name of the channel in which the command was issued,
or the sender's nickname if this was a private message.

=item * C<ARG2>: a string of arguments to the command, or hash reference with
arguments in case you defined command along with arguments, or undef if there
were no arguments

=back

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut
