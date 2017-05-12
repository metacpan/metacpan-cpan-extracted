package POE::Component::IRC::Plugin::MultiProxy::State;
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::State::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::State::VERSION = '0.01';
}

use strict;
use warnings FATAL => 'all';
use POE::Filter::IRCD;
use POE::Component::IRC::Common qw(parse_user u_irc);
use POE::Component::IRC::Plugin qw(:ALL);

sub new {
    my ($package) = @_;
    return bless { }, $package;
}

sub PCI_register {
    my ($self, $irc) = @_;
    $self->{irc} = $irc;
    $self->{filter} = POE::Filter::IRCD->new();
    $irc->plugin_register($self, SERVER => qw(001 away_sync_start away_sync_end join chan_mode chan_sync chan_sync_invex chan_sync_excepts nick_sync raw));
    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = @_;
    return 1;
}

sub S_001 {
    my ($self, $irc) = splice @_, 0, 2;
    $self->{syncing_away} = { };
    $self->{syncing_op}   = { };
    $self->{syncing_join} = { };
    $self->{op_queue}     = { };
    $self->{join_queue}   = { };

    return PCI_EAT_NONE;
}

sub S_join {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping = $irc->isupport('CASEMAPPING');
    my $unick = u_irc((parse_user(${ $_[0] }))[0], $mapping);
    my $uchan = u_irc(${ $_[1] }, $mapping);

    if ($unick eq u_irc($irc->nick_name(), $mapping)) {
        $self->{syncing_join}{$uchan} = 1;
    }
    else {
        $self->{syncing_join}{$unick}++;
    }

    return PCI_EAT_NONE;
}

sub S_away_sync_start {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping = $irc->isupport('CASEMAPPING');
    my $uchan = u_irc(${ $_[0] }, $mapping);

    $self->{syncing_away}{$uchan} = 1;
    return PCI_EAT_NONE;
}

sub S_away_sync_end {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping = $irc->isupport('CASEMAPPING');
    my $uchan = u_irc(${ $_[0] }, $mapping);

    delete $self->{syncing_away}{$uchan};
    return PCI_EAT_NONE;
}

sub S_chan_mode {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping  = $irc->isupport('CASEMAPPING');
    my $uchan    = u_irc(${ $_[1] }, $mapping);
    my $mode     = ${ $_[2] };
    my $unick    = u_irc($irc->nick_name(), $mapping);

    if ($mode =~ /\+o/) {
        my @operands = split / /, ${ $_[3] };
        if (grep { u_irc($_, $mapping) eq $unick } @operands) {
            $self->{syncing_op}{$uchan}{invex} = 1;
            $self->{syncing_op}{$uchan}{excepts} = 1;
        }
    }

    return PCI_EAT_NONE;
}

sub S_chan_sync {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping = $irc->isupport('CASEMAPPING');
    my $uchan = u_irc(${ $_[0] }, $mapping);

    delete $self->{syncing_join}{$uchan};
    $self->_flush_queue($self->{join_queue}{$uchan});
    return PCI_EAT_NONE;
}

sub S_chan_sync_invex {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping = $irc->isupport('CASEMAPPING');
    my $uchan = u_irc(${ $_[0] }, $mapping);

    $self->_flush_queue($self->{op_queue}{$uchan}{invex});
    delete $self->{syncing_op}{$uchan}{invex};
    delete $self->{syncing_op}{$uchan} if !keys %{ $self->{syncing_op}{$uchan} };
    return PCI_EAT_NONE;
}

sub S_chan_sync_excepts {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping = $irc->isupport('CASEMAPPING');
    my $uchan = u_irc(${ $_[0] }, $mapping);

    $self->_flush_queue($self->{op_queue}{$uchan}{excepts});
    delete $self->{syncing_op}{$uchan}{excepts};
    delete $self->{syncing_op}{$uchan} if !keys %{ $self->{syncing_op}{$uchan} };
    return PCI_EAT_NONE;
}

sub S_nick_sync {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping = $irc->isupport('CASEMAPPING');
    my $unick = u_irc(${ $_[0] }, $mapping);

    $self->{syncing_join}{$unick}--;
    delete $self->{syncing_join}{$unick} if $self->{syncing_join}{$unick} == 0;
    $self->_flush_queue($self->{join_queue}{$unick});
    return PCI_EAT_NONE;
}

sub S_raw {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping = $irc->isupport('CASEMAPPING');
    my $raw_line = ${ $_[0] };
    my $input = $self->{filter}->get( [ $raw_line ] )->[0];

    # syncing_join me
    if ($input->{command} =~ /315|324|329|352|367|368/) {
        if ($input->{params}[1] =~ /[^#&+!]/) {
            if ($self->{syncing_join}{u_irc($input->{params}[1], $mapping)}) {
                return PCI_EAT_PLUGIN;
            }
        }
    }

    # syncing_join other
    if ($input->{command} eq '352') {
        if ($self->{syncing_join}{u_irc($input->{params}[5], $mapping)}) {
            return PCI_EAT_PLUGIN;
        }
    }

    # syncing_away
    if ($input->{command} =~ /315|352/) {
        if ($input->{params}[1] =~ /[^#&+!]/) {
            if ($self->{syncing_away}{u_irc($input->{params}[1], $mapping)}) {
                return PCI_EAT_PLUGIN;
            }
        }
    }

    # syncing_op invex
    if ($input->{command} =~ /346|347/) {
        if ($self->{syncing_op}{u_irc($input->{params}[1], $mapping)}{invex}) {
            return PCI_EAT_PLUGIN;
        }
    }

    # syncing_op excepts
    if ($input->{command} =~ /348|349/) {
        if ($self->{syncing_op}{u_irc($input->{params}[1], $mapping)}{excepts}) {
            return PCI_EAT_PLUGIN;
        }
    }

    return PCI_EAT_NONE;
}

sub _flush_queue {
    my ($self, $queue) = @_;
    return if !$queue;

    while (my $request = shift @$queue) {
        my ($callback, $reply, $real_what, $args) = @{ $request };
        $callback->($_) for $self->$reply($real_what, @{ $args });
    }

    return;
}

sub is_syncing {
    my ($self, $what) = @_;
    my $mapping = $self->{irc}->isupport('CASEMAPPING');
    my $uwhat = u_irc($what, $mapping);

    return 1 if $self->{syncing_join}{$uwhat};
    return;
}

sub enqueue {
    my ($self, $callback, $reply, $what, @args) = @_;
    my $mapping = $self->{irc}->isupport('CASEMAPPING');
    my $uwhat = u_irc($what, $mapping);

    if ($reply eq 'mode_reply') {
        if (grep { defined && $_ eq 'e' } @args && $self->{syncing_op}{$uwhat}{excepts}) {
            push @{ $self->{op_queue}{$uwhat}{excepts} }, [$callback, $reply, $what, \@args];
            return;
        }
        elsif (grep { defined && $_ eq 'I' } @args && $self->{syncing_op}{$uwhat}{invex}) {
            push @{ $self->{op_queue}{$uwhat}{invex} }, [$callback, $reply, $what, \@args];
            return;
        }
        elsif ($self->{syncing_join}{$uwhat}) {
            push @{ $self->{join_queue}{$uwhat} }, [$callback, $reply, $what, \@args];
            return;
        }
    }
    elsif ($reply =~ /(?:who|names|topic)_reply/) {
        if ($self->{syncing_join}{$uwhat}) {
            push @{ $self->{join_queue}{$uwhat} }, [$callback, $reply, $what, \@args];
            return;
        }
    }

    my @lines = $self->$reply($what, @args);
    $callback->(@lines);
    return;
}

# handles /^TOPIC (\S+)$/ where $1 is a channel that we're on
sub topic_reply {
    my ($self, $chan) = @_;
    my $irc     = $self->{irc};
    my $me      = $irc->nick_name();
    my $server  = $irc->server_name();
    my @results;

    if (!keys %{ $irc->channel_topic($chan) }) {
        push @results, ":$server 331 $me $chan :No topic is set";
    }
    else {
        my $topic_info = $irc->channel_topic($chan);
        push @results, ":$server 332 $me $chan :" . $topic_info->{Value};
        push @results, ":$server 333 $me $chan " . join(' ', @{$topic_info}{qw(SetBy SetAt)});
    }

    return @results;

}

# handles /^NAMES (\S+)$/ where $1 is a channel that we're on
sub names_reply {
    my ($self, $chan) = @_;
    my $irc       = $self->{irc};
    my $me        = $irc->nick_name();
    my $server    = $irc->server_name(); 
    my $chan_type = '=';
    $chan_type    = '@' if $irc->is_channel_mode_set($chan, 's');
    $chan_type    = '*' if $irc->is_channel_mode_set($chan, 'p');

    my @nicks = sort map { 
        my $nick = $_;
        my $prefix = '';
        $prefix = '+' if $irc->has_channel_voice($chan, $nick);
        $prefix = '%' if $irc->is_channel_halfop($chan, $nick);
        $prefix = '@' if $irc->is_channel_operator($chan, $nick);
        $prefix . $nick;
    } $irc->channel_list($chan);

    my $length = length($server) + length($chan) + length($me) + 11;
    my @results;
    my $nick_list = shift @nicks;

    for my $nick (@nicks) {
        if (length("$nick_list $nick") + $length <= 510) {
            $nick_list .= " $nick";
        }
        else {
            push @results, ":$server 353 $me $chan_type $chan :$nick_list";
            $nick_list = $nick;
        }
    }

    push @results, ":$server 353 $me $chan_type $chan :$nick_list";
    push @results, ":$server 366 $me $chan :End of NAMES list";

    return @results;
}

# handles /^WHO (\S+)$/ where $1 is a channel we're on or a nickname, NOT a mask
sub who_reply {
    my ($self, $who) = @_;
    my $irc     = $self->{irc};
    my $me      = $irc->nick_name();
    my $server  = $irc->server_name();
    my $prefix  = $who =~ /^[#&+!]/ ? $who : '*';

    my @members;
    @members = $irc->channel_list($who) if $irc->is_channel_member($who, $me);
    @members = ($who) if $irc->_nick_exists($who);

    my @results;
    for my $member (@members) {
        my ($nick, $user, $host) = parse_user($irc->nick_long_form($member));

        my $status = $irc->is_away($nick) ? 'G' : 'H';
        $status .= '*' if $irc->is_operator($nick);
        $status .= '@' if $irc->is_channel_operator($who, $nick);
        $status .= '%' if $irc->is_channel_halfop($who, $nick);
        $status .= '+' if $irc->has_channel_voice($who, $nick) && !$irc->is_channel_operator($who, $nick);

        my $info = $irc->nick_info($nick);
        my $real        = defined $info->{Real}   ? $info->{Real} : '';
        my $user_server = defined $info->{Server} ? $info->{Server} : '*';
        my $hops        = defined $info->{Hops}   ? $info->{Hops} : '*';
        push @results, ":$server 352 $me $prefix $user $host $user_server $nick $status :$hops $real";
    }

    push @results, ":$server 315 $me $who :End of WHO list";
    return @results;
}

# handles /^MODE #chan( [Ieb])?$/ and /^MODE our_nick$/
sub mode_reply {
    my ($self, $chan, $type) = @_;
    my $irc     = $self->{irc};
    my $mapping = $irc->isupport('CASEMAPPING');
    my $me      = $irc->nick_name();
    my $server  = $irc->server_name();
    my @results;

    if (u_irc($chan, $mapping) eq u_irc($me, $mapping)) {
        return ":$server 221 $me :+" . $irc->umode();
    }
    elsif (!defined $type) {
        my $modes = $irc->channel_modes($chan);

        my $mode_string = '';
        while (my ($mode, $arg) = each %{ $modes }) {
            if (!length $arg) {
                $mode_string .= $mode;
                delete $modes->{$mode};
            }
        }

        my @args;
        while (my ($mode, $arg) = each %{ $modes }) {
            $mode_string .= $mode;
            push @args, $arg;
        }

        $mode_string .= ' ' . join ' ', @args if @args;        
        push @results, ":$server 324 $me $chan +$mode_string";

        if ($irc->channel_creation_time($chan)) {
            my $time = $irc->channel_creation_time($chan);
            push @results, ":$server 329 $me $chan $time";
        }
    }
    elsif ($type eq 'I') {
        while (my ($mask, $info) = each %{ $irc->channel_invex_list($chan) }) {
            push @results, ":$server 346 $me $chan $mask " . join (' ', @{$info}{qw(SetBy SetAt)});
        }
        push @results, ":$server 347 $me $chan :End of Channel Invite List";
    }
    elsif ($type eq 'e') {
        while (my ($mask, $info) = each %{ $irc->channel_except_list($chan) }) {
            push @results, ":$server 348 $me $chan $mask " . join (' ', @{$info}{qw(SetBy SetAt)});
        }
        push @results, ":$server 349 $me $chan :End of Channel Exception List";
    }
    elsif ($type eq 'b') {
        while (my ($mask, $info) = each %{ $irc->channel_ban_list($chan) }) {
            push @results, ":$server 367 $me $chan $mask " . join (' ', @{$info}{qw(SetBy SetAt)});
        }
        push @results, ":$server 368 $me $chan :End of Channel Ban List";
    }

    return @results;
}

1;

=encoding utf8

=head1 NAME

POE::Compoent::IRC::Plugin::MultiProxy::State - Generates IRC server replies based on information provided by POE::Component::IRC::State

=head1 SYNOPSIS

 use POE::Compoent::IRC::Plugin::MultiProxy::State;

 $irc->plugin_add('State', POE::Compoent::IRC::Plugin::MultiProxy::State->new());

=head1 DESCRIPTION

POE::Compoent::IRC::Plugin::MultiProxy::::State is a
L<POE::Component::IRC|POE::Component::IRC> plugin. Its role is to use
L<POE::Component::IRC::State|POE::Component::IRC::State>'s information as a
cache so that fewer trips will be to the IRC server when clients submit
queries. The methods here are only useful for a subset of the use cases that
their corresponding commands are capable of, mostly because there are certain
cases that only the actual IRC server can handle. However, the methods can
handle all the automatic queries that modern IRC clients make, so it does the
job.

Another thing this plugin does is hide from clients all server replies
elicited by L<POE::Component::IRC::State|POE::Component::IRC::State>'s
information gathering.

This plugin requires the IRC component to be
L<POE::Component::IRC::State|POE::Component::IRC::State> or a subclass thereof.

=head1 CONSTRUCTOR

=head2 C<new>

Takes no arguments.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add()> method.

=head1 METHODS

=head2 C<topic_reply>

One argument:

An IRC channel which the IRC component is on

Returns IRC protocol line responses to the C<TOPIC> command.

=head2 C<names_reply>

One argument:

An IRC channel which the IRC component is on

Returns IRC protocol line responses to the C<NAMES> command.

=head2 C<who_reply>

One argument:

An IRC channel which the IRC component is on, or a known nickname

Returns IRC protocol line responses to the C<WHO> command.

=head2 C<names_reply>

One or two arguments:

The IRC component's nickname, or a channel which the component is on
and an optional mode type

Returns IRC protocol line responses to the C<MODE> command.

=head2 C<enqueue>

In case a client asks for information about a channel while it is being
synced, it should call this method, and the information will be provided
as soon as it has been gathered.

Takes three arguments:

A code reference which will be called for every line of response generated,
the type of reply being asked for (e.g. 'who_reply'), and the arguments
to the corresponding method.

=head2 C<is_syncing>

Takes one argument:

An IRC channel.

Returns 1 if the channel or nick is being synced, 0 otherwise.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut
