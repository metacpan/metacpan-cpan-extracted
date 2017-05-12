package POE::Component::IRC::Plugin::MultiProxy::Recall;
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::Recall::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::Recall::VERSION = '0.01';
}

use strict;
use warnings FATAL => 'all';
use File::Temp qw(tempfile);
use POE;
use POE::Component::IRC::Common qw( parse_user );
use POE::Component::IRC::Plugin qw( :ALL );
use POE::Component::IRC::Plugin::BotTraffic;
use POE::Filter::IRCD;
use Tie::File;

sub new {
    my ($package, %self) = @_;
    if (!$self{Mode} || $self{Mode} !~ /missed|all|none/) {
        $self{Mode} = 'missed';
    }
    return bless \%self, $package;
}

sub PCI_register {
    my ($self, $irc) = @_;

    if (!$irc->isa('POE::Component::IRC::State')) {
        die __PACKAGE__ . " requires PoCo::IRC::State or a subclass thereof\n";
    }

    if (!grep { $_->isa('POE::Component::IRC::Plugin::BotTraffic') } values %{ $irc->plugin_list() }) {
        $irc->plugin_add('BotTraffic', POE::Component::IRC::Plugin::BotTraffic->new());
    }

    ($self->{state})     = grep { $_->isa('POE::Component::IRC::Plugin::MultiProxy::State') } values %{ $irc->plugin_list() };
    $self->{irc}         = $irc;
    $self->{filter}      = POE::Filter::IRCD->new();
    $self->{recall}      = [ ];
    $self->{clients}     = 0;
    $self->{last_detach} = 0;

    tie @{ $self->{recall} }, 'Tie::File', scalar tempfile() if $self->{Mode} =~ /all|missed/;

    $irc->raw_events(1);
    $irc->plugin_register($self, 'SERVER', qw(cap bot_ctcp_action bot_public connected ctcp_action msg public part proxy_authed proxy_close raw));

    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = @_;
    delete $self->{irc};
    return 1;
}

sub S_cap {
    my ($self, $irc) = splice @_, 0, 2;
    my $cmd = ${ $_[0] };

    if ($cmd eq 'ACK') {
        my $list = ${ $_[1] } eq '*' ? ${ $_[2] } : ${ $_[1] };
        my @enabled = split / /, $list;

        if (grep { $_ =~ /^=?identify-msg$/ } @enabled) {
            $self->{idmsg} = 1;
        }
        if (grep { $_ =~ /^-identify-msg$/ } @enabled) {
            $self->{idmsg} = 0;
        }
    }
    return PCI_EAT_NONE;
}

sub S_bot_ctcp_action {
    my ($self, $irc) = splice @_, 0, 2;
    my $recipients   = join (',', @{ ${ $_[0] } });
    my $msg          = ${ $_[1] };

    if ($self->{Mode} eq 'all') {
        my $line = ':' . $irc->nick_long_form($irc->nick_name()) . " PRIVMSG $recipients :\x01ACTION $msg\x01";
        push @{ $self->{recall} }, $line;
    }

    return PCI_EAT_NONE;
}

sub S_bot_public {
    my ($self, $irc) = splice @_, 0, 2;
    my $recipients   = join (',', @{ ${ $_[0] } });
    my $msg          = ${ $_[1] };

    if ($self->{Mode} eq 'all') {
        my $line = ':' . $irc->nick_long_form($irc->nick_name()) . " PRIVMSG $recipients :$msg";
        push @{ $self->{recall} }, $line;
    }

    return PCI_EAT_NONE;
}

sub S_connected {
    my ($self, $irc) = splice @_, 0, 2;

    $self->{stash}    = [ ];
    $self->{stashing} = 1;
    $self->{idmsg}    = 0;
    return PCI_EAT_NONE;
}

sub S_ctcp_action {
    my ($self, $irc) = splice @_, 0, 2;
    my $sender       = ${ $_[0] };
    my $recipients   = ${ $_[1] };
    my $msg          = ${ $_[2] };

    for my $recipient (@{ $recipients }) {
        if ($recipient eq $irc->nick_name()) {
            # private ACTION
            if (!$self->{clients}) {
                my $line = ":$sender PRIVMSG $irc->nick_name :\x01ACTION $msg\x01";
                push @{ $self->{recall} }, $line;
            }
        }
        elsif ($self->{Mode} eq 'all' || $self->{Mode} eq 'missed' && !$self->{clients}) {
            # channel ACTION
            my $line = ":$sender PRIVMSG $recipient :\x01ACTION $msg\x01";
            push @{ $self->{recall} }, $line;
        }
    }

    return PCI_EAT_NONE;
}

sub S_msg {
    my ($self, $irc) = splice @_, 0, 2;
    my $sender       = ${ $_[0] };
    my $msg          = ${ $_[2] };

    return PCI_EAT_NONE if $self->{clients};

    my $line = ":$sender PRIVMSG $irc->nick_name :$msg";
    push @{ $self->{recall} }, $line;
    return PCI_EAT_NONE;
}

sub S_part {
    my ($self, $irc) = splice @_, 0, 2;
    my $chan         = ${ $_[1] };

    if (my $cycle = grep { $_->isa('POE::Component::IRC::Plugin::CycleEmpty') } values %{ $irc->plugin_list() } ) {
        return PCI_EAT_NONE if $cycle->cycling($chan);
    }

    # too CPU-heavy
#    if ($self->{Mode} eq 'all') {
#        # remove all messages related to this channel
#        my $input = $self->{filter}->get( $self->{recall} );
#        for my $line (0..$#{ $self->{recall} }) {
#            if (lc $input->[$line]{params}[0] eq lc $chan) {
#                delete $self->{recall}[$line];
#            }
#            elsif ($input->[$line]{command} =~ /332|333|366/ && lc $input->[$line]{params}[1] eq lc $chan) {
#                delete $self->{recall}[$line];
#            }
#            elsif ($input->[$line]{command} eq '353' && lc $input->[$line]{params}->[2] eq lc $chan) {
#                delete $self->{recall}[$line];
#            }
#        }
#    }

    return PCI_EAT_NONE;
}

sub S_public {
    my ($self, $irc) = splice @_, 0, 2;
    my $sender       = ${ $_[0] };
    my $chan         = ${ $_[1] }->[0];
    my $msg          = ${ $_[2] };

    # do this here instead rather than in S_raw so that IDENTIFY-MSG
    # will by handled by POE::Filter::IRC::Compat
    if ($self->{Mode} eq 'all' || $self->{Mode} eq 'missed' && !$self->{clients}) {
        push @{ $self->{recall} }, ":$sender PRIVMSG $chan :$msg";
    }

    return PCI_EAT_NONE;
}

sub S_proxy_authed {
    my ($self, $irc) = splice @_, 0, 2;
    $self->{clients}++;
    return PCI_EAT_NONE;
}

sub S_proxy_close {
    my ($self, $irc) = splice @_, 0, 2;
    $self->{clients}--;
    return if $self->{clients};

    $self->{recall} = [ ] if $self->{Mode} =~ /^(?:missed|none)$/;

    if ($self->{Mode} eq 'missed') {
        push @{ $self->{recall} }, $self->_chan_info();
    }
    elsif ($self->{Mode} eq 'all') {
        $self->{last_detach} = $#{ $self->{recall} };
    }

    return PCI_EAT_NONE;
}

sub S_raw {
    my ($self, $irc) = splice @_, 0, 2;
    my $raw_line = ${ $_[0] };
    my $input = $self->{filter}->get( [ $raw_line ] )->[0];

    if ($self->{stashing}) {
        # capture all numeric commands until we've got the MOTD
        if ($input->{command} =~ /\d{3}/) {
            push @{ $self->{stash} }, $raw_line;
        }
        # RPL_ENDOFMOTD / ERR_NOMOTD
        if ($input->{command} =~ /376|422/) {
            $self->{stashing} = 0;
        }
    }

    if ($self->{Mode} eq 'all' || $self->{Mode} eq 'missed' && !$self->{clients}) {
        if ($input->{command} eq 'MODE' && $input->{params}[1] =~ /^[#&+!]/) {
            # channel mode changes
            push @{ $self->{recall} }, $raw_line;
        }
        elsif ($input->{command} =~ /JOIN|KICK|PART|QUIT|NICK|TOPIC/) {
            # other channel-related things
            push @{ $self->{recall} }, $raw_line;
        }
        elsif ($input->{command} eq '353') {
            # only log this when we've just joined the channel
            push @{ $self->{recall} }, $raw_line if $self->{state}->is_syncing($input->{params}[2]);
        }
        elsif ($input->{command} =~ /332|333|366/) {
            # only log these when we've just joined the channel
            push @{ $self->{recall} }, $raw_line if $self->{state}->is_syncing($input->{params}[1]);
        }
    }

    return PCI_EAT_NONE;
}

# returns everything that an IRC server would send us upon joining
# the channels we're on
sub _chan_info {
    my ($self) = @_;
    my $irc    = $self->{irc};
    my $state  = $self->{state};
    my $me     = $irc->nick_name();

    my @info;
    for my $chan (keys %{ $irc->channels() }) {
        push @info, ':' . $irc->nick_long_form($me) . " JOIN :$chan";
        push @info, $state->topic_reply($chan) if keys %{ $irc->channel_topic($chan) };
        push @info, $state->names_reply($chan);
    }

    return @info;
}

sub recall {
    my ($self) = @_;
    my $irc    = $self->{irc};
    my $me     = $irc->nick_name();
    my $server = $irc->server_name();
    my @lines;

    for my $line (@{ $self->{stash} }) {
        $line =~ s/^(\S+ +\S+) +\S+ +(.*)/$1 $me $2/;
        push @lines, $line;
    }

    push @lines, ":$server MODE $me :" . $irc->umode() if $irc->umode();
    push @lines, @{ $self->{recall} };
    push @lines, ":$server CAP * ACK :identify-msg" if $self->{idmsg};

    if ($self->{Mode} eq 'all' && $#{ $self->{recall} } > $self->{last_detach}) {
        # remove all PMs received since we last detached
        for my $line ($self->{last_detach} .. $#{ $self->{recall} }) {
            my $in = shift @{ $self->{filter}->get( $self->{recall} ) };
            if ($in->{command} eq 'PRIVMSG' && $in->{params}[0] !~ /^[#&+!]/) {
                delete $self->{recall}[$line];
            }
        }
    }
    elsif ($self->{Mode} eq 'none') {
        push @lines, $self->_chan_info();
    }

    return @lines;
}

1;

=encoding utf8

=head1 NAME

POE::Compoent::IRC::Plugin::MultiProxy::Recall - A PoCo-IRC plugin which can greet proxy clients with the messages they missed while they were away

=head1 SYNOPSIS

 use POE::Compoent::IRC::Plugin::MultiProxy::Recall;

 $irc->plugin_add('Recall', POE::Compoent::IRC::Plugin::MultiProxy::Recall->new( Mode => 'missed' ));

=head1 DESCRIPTION

This plugin requires the IRC component to be
L<POE::Component::IRC::State|POE::Component::IRC::State> or a subclass thereof.
It also requires a
L<POE::Component::IRC::Plugin::BotTraffic|POE::Component::IRC::Plugin::BotTraffic>
to be in the plugin pipeline. It will be added automatically if it is not present.

=head1 METHODS

=head2 C<new>

One optional argument:

B<'Mode'>, which public messages you want it to recall. B<'missed'>, the
default, makes it only recall public messages that were received while no
proxy client was attached. B<'all'> will recall public messages from all
channels since they were joined. B<'none'> will recall none. The plugin will
always recall missed private messages, regardless of this option.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add()> method.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut
