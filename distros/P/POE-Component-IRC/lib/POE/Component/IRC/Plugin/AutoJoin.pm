package POE::Component::IRC::Plugin::AutoJoin;
BEGIN {
  $POE::Component::IRC::Plugin::AutoJoin::AUTHORITY = 'cpan:HINRIK';
}
$POE::Component::IRC::Plugin::AutoJoin::VERSION = '6.88';
use strict;
use warnings FATAL => 'all';
use Carp;
use IRC::Utils qw(parse_user lc_irc);
use POE::Component::IRC::Plugin qw(:ALL);

sub new {
    my ($package) = shift;
    croak "$package requires an even number of arguments" if @_ & 1;
    my %self = @_;
    return bless \%self, $package;
}

sub PCI_register {
    my ($self, $irc) = @_;

    if (!$self->{Channels}) {
        if ($irc->isa('POE::Component::IRC::State')) {
            for my $chan (keys %{ $irc->channels() }) {
                my $lchan = lc_irc($chan, $irc->isupport('MAPPING'));
                # note that this will not get the real key on ircu servers
                # in channels where we don't have ops
                my $key = $irc->is_channel_mode_set($chan, 'k')
                    ? $irc->channel_key($chan)
                    : ''
                ;

                $self->{Channels}->{$lchan} = $key;
            }
        }
        else {
            $self->{Channels} = {};
        }
    }
    elsif (ref $self->{Channels} eq 'ARRAY') {
        my %channels;
        $channels{lc_irc($_, $irc->isupport('MAPPING'))} = undef for @{ $self->{Channels} };
        $self->{Channels} = \%channels;
    }

    $self->{tried_keys} = { };
    $self->{Rejoin_delay} = 5 if !defined $self->{Rejoin_delay};
    $self->{NickServ_delay} = 5 if !defined $self->{NickServ_delay};
    $irc->plugin_register($self, 'SERVER', qw(001 474 isupport chan_mode join kick part identified));
    $irc->plugin_register($self, 'USER', qw(join));
    return 1;
}

sub PCI_unregister {
    return 1;
}

sub S_001 {
    my ($self, $irc) = splice @_, 0, 2;
    delete $self->{alarm_ids};
    return PCI_EAT_NONE;
}

# we join channels after S_isupport in case the server supports
# CAPAB IDENTIFY-MSG, so pocoirc can turn it on before we join channels
sub S_isupport {
    my ($self, $irc) = splice @_, 0, 2;

    if (!grep { $_->isa('POE::Component::IRC::Plugin::NickServID') } values %{ $irc->plugin_list() }) {
        # we don't have to wait for NickServ, so let's join
        while (my ($chan, $key) = each %{ $self->{Channels} }) {
            $irc->yield(join => $chan => (defined $key ? $key : ()));
        }
    }
    else {
        while (my ($chan, $key) = each %{ $self->{Channels} }) {
            push @{ $self->{alarm_ids} }, $irc->delay(
                [join => $chan => (defined $key ? $key : ())],
                $self->{NickServ_delay},
            );
        }
    }
    return PCI_EAT_NONE;
}

sub S_identified {
    my ($self, $irc) = splice @_, 0, 2;

    if ($self->{alarm_ids}) {
        $irc->delay_remove($_) for @{ $self->{alarm_ids} };
        delete $self->{alarm_ids};

        while (my ($chan, $key) = each %{ $self->{Channels} }) {
            $irc->yield(join => $chan => (defined $key ? $key : ()));
        }
    }
    return PCI_EAT_NONE;
}

# ERR_BANNEDFROMCHAN
sub S_474 {
    my ($self, $irc) = splice @_, 0, 2;
    my $chan = ${ $_[2] }->[0];
    my $lchan = lc_irc($chan, $irc->isupport('MAPPING'));
    return PCI_EAT_NONE if !$self->{Retry_when_banned};

    my $key = $self->{Channels}{$lchan};
    $key = $self->{tried_keys}{$lchan} if defined $self->{tried_keys}{$lchan};
    $irc->delay([join => $chan => (defined $key ? $key : ())], $self->{Retry_when_banned});
    return PCI_EAT_NONE;
}

sub S_chan_mode {
    my ($self, $irc) = splice @_, 0, 2;
    pop @_;
    my $chan  = ${ $_[1] };
    my $mode  = ${ $_[2] };
    my $arg   = defined $_[3] ? ${ $_[3] } : '';
    my $lchan = lc_irc($chan, $irc->isupport('MAPPING'));

    $self->{Channels}->{$lchan} = $arg if $mode eq '+k';
    $self->{Channels}->{$lchan} = '' if $mode eq '-k';
    return PCI_EAT_NONE;
}

sub S_join {
    my ($self, $irc) = splice @_, 0, 2;
    my $joiner = parse_user(${ $_[0] });
    my $chan   = ${ $_[1] };
    my $lchan  = lc_irc($chan, $irc->isupport('MAPPING'));

    return PCI_EAT_NONE if $joiner ne $irc->nick_name();
    delete $self->{alarm_ids};

    if (defined $self->{tried_keys}{$lchan}) {
        $self->{Channels}->{$lchan} = $self->{tried_keys}{$lchan};
        delete $self->{tried_keys}{$lchan};
    }
    else {
        $self->{Channels}->{$lchan} = '';
    }

    return PCI_EAT_NONE;
}

sub S_kick {
    my ($self, $irc) = splice @_, 0, 2;
    my $chan   = ${ $_[1] };
    my $victim = ${ $_[2] };
    my $lchan  = lc_irc($chan, $irc->isupport('MAPPING'));

    if ($victim eq $irc->nick_name()) {
        if ($self->{RejoinOnKick}) {
            $irc->delay([
                'join',
                $chan,
                (defined $self->{Channels}->{$lchan} ? $self->{Channels}->{$lchan} : ())
            ], $self->{Rejoin_delay});
        }
        delete $self->{Channels}->{$lchan};
    }
    return PCI_EAT_NONE;
}

sub S_part {
    my ($self, $irc) = splice @_, 0, 2;
    my $parter = parse_user(${ $_[0] });
    my $chan   = ${ $_[1] };
    my $lchan  = lc_irc($chan, $irc->isupport('MAPPING'));

    delete $self->{Channels}->{$lchan} if $parter eq $irc->nick_name();
    return PCI_EAT_NONE;
}

sub U_join {
    my ($self, $irc) = splice @_, 0, 2;
    my (undef, $chan, $key) = split /\s/, ${ $_[0] }, 3;
    my $lchan = lc_irc($chan, $irc->isupport('MAPPING'));

    $self->{tried_keys}->{$lchan} = $key if defined $key;
    return PCI_EAT_NONE;
}

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::AutoJoin - A PoCo-IRC plugin which
keeps you on your favorite channels

=head1 SYNOPSIS

 use POE qw(Component::IRC::State Component::IRC::Plugin::AutoJoin);

 my $nickname = 'Chatter';
 my $server = 'irc.blahblahblah.irc';

 my %channels = (
     '#Blah'   => '',
     '#Secret' => 'secret_password',
     '#Foo'    => '',
 );

 POE::Session->create(
     package_states => [
         main => [ qw(_start irc_join) ],
     ],
 );

 $poe_kernel->run();

 sub _start {
     my $irc = POE::Component::IRC::State->spawn(
         Nick => $nickname,
         Server => $server,
     ) or die "Oh noooo! $!";

     $irc->plugin_add('AutoJoin', POE::Component::IRC::Plugin::AutoJoin->new( Channels => \%channels ));
     $irc->yield(register => qw(join);
     $irc->yield(connect => { } );
 }

 sub irc_join {
     my $chan = @_[ARG1];
     $irc->yield(privmsg => $chan => "hi $channel!");
 }


=head1 DESCRIPTION

POE::Component::IRC::Plugin::AutoJoin is a L<POE::Component::IRC|POE::Component::IRC>
plugin. If you get disconnected, the plugin will join all the channels you were
on the next time it gets connected to the IRC server. It can also rejoin a
channel if the IRC component gets kicked from it. It keeps track of channel
keys so it will be able to rejoin keyed channels in case of reconnects/kicks.

If a L<POE::Component::IRC::Plugin::NickServID|POE::Component::IRC::Plugin::NickServID>
plugin has been added to the IRC component, then AutoJoin will wait for a
reply from NickServ before joining channels on connect.

This plugin requires the IRC component to be
L<POE::Component::IRC::State|POE::Component::IRC::State> or a subclass thereof.

=head1 METHODS

=head2 C<new>

Takes the following optional arguments:

B<'Channels'>, either an array reference of channel names, or a hash reference
keyed on channel name, containing the password for each channel. By default it
uses the channels the component is already on if you are using
L<POE::Component::IRC::State|POE::Component::IRC::State>.

B<'RejoinOnKick'>, set this to 1 if you want the plugin to try to rejoin a
channel (once) if you get kicked from it. Default is 0.

B<'Rejoin_delay'>, the time, in seconds, to wait before rejoining a channel
after being kicked (if B<'RejoinOnKick'> is on). Default is 5.

B<'Retry_when_banned'>, if you can't join a channel due to a ban, set this
to the number of seconds to wait between retries. Default is 0 (disabled).

B<'NickServ_delay'>, how long (in seconds) to wait for a reply from NickServ
before joining channels. Default is 5.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add> method.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut
