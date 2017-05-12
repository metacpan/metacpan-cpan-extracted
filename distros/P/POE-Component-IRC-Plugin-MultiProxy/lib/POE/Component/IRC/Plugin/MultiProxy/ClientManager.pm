package POE::Component::IRC::Plugin::MultiProxy::ClientManager;
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::ClientManager::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::ClientManager::VERSION = '0.01';
}

use strict;
use warnings FATAL => 'all';
use Carp;
use POE qw(Filter::Line Filter::Stackable);
use POE::Component::IRC::Common qw( u_irc );
use POE::Component::IRC::Plugin qw( :ALL );
use POE::Filter::IRCD;

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub PCI_register {
    my ($self, $irc) = @_;

    if (!$irc->isa('POE::Component::IRC::State')) {
        die __PACKAGE__ . " requires PoCo::IRC::State or a subclass thereof\n";
    }

    for my $plugin (qw(Recall State)) {
        my $full = "POE::Component::IRC::Plugin::MultiProxy::$plugin";

        if (!grep { $_->isa($full) } values %{ $irc->plugin_list() } ) {
            die __PACKAGE__ . " requires $full\n";
        }
    }

    $self->{ircd_filter} = POE::Filter::IRCD->new();
    $self->{wheels} = { };

    ($self->{state}) = grep { $_->isa('POE::Component::IRC::Plugin::MultiProxy::State') } values %{ $irc->plugin_list() };
    $self->{irc} = $irc;
    $irc->raw_events(1);
    $irc->plugin_register($self, 'SERVER', qw(raw));

    POE::Session->create(
        object_states => [
            $self => [ qw(_start _client_new _client_error _client_input _drop_client) ],
        ],
    );

    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = @_;

    for my $id (keys %{ $self->{wheels} }) {
        $poe_kernel->call("$self", '_drop_client', $id);
    }
    $poe_kernel->alias_remove("$self");
    return 1;
}

sub add_client {
    my ($self, $socket) = @_;
    $poe_kernel->call("$self", '_client_new', $socket);
    return;
}

sub _start {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $kernel->alias_set("$self");
    return;
}

sub _client_new {
    my ($self, $socket) = @_[OBJECT, ARG0];

    my $filter = POE::Filter::Stackable->new(
        Filters => [
            POE::Filter::Line->new(),
            POE::Filter::IRCD->new(),
        ]
    );

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle       => $socket,
        InputFilter  => $filter,
        OutputFilter => POE::Filter::Line->new(),
        InputEvent   => '_client_input',
        ErrorEvent   => '_client_error',
    );

    $self->{wheels}{$wheel->ID} = $wheel;

    my ($recall_plug) = grep { $_->isa('POE::Component::IRC::Plugin::MultiProxy::Recall') } values %{ $self->{irc}->plugin_list() };
    $wheel->put($recall_plug->recall());
    return;
}

sub _client_error {
    my ($kernel, $wheel_id) = @_[KERNEL, ARG3];
    $kernel->yield('_drop_client', $wheel_id);
    return;
}

sub _client_input {
    my ($kernel, $self, $input, $wheel_id) = @_[KERNEL, OBJECT, ARG0, ARG1];
    my $irc   = $self->{irc};
    my $state = $self->{state};
    my $wheel = $self->{wheels}{$wheel_id};

    if ($input->{command} eq 'QUIT') {
        $kernel->yield('_drop_client', $wheel->ID);
        return;
    }
    elsif ($input->{command} eq 'PING') {
        $wheel->put('PONG'.(defined $input->{params}[0] ? " $input->{params}[0]" : ''));
        return;
    }
    elsif ($input->{command} eq 'PRIVMSG') {
        my ($recipient, $msg) = @{ $input->{params} }[0..1];
        if ($recipient =~ /^[#&+!]/) {
            # recreate channel messages from this client for
            # other clients to see
            my $line = ':' . $irc->nick_long_form($irc->nick_name()) . " PRIVMSG $recipient :$msg";

            for my $other (values %{ $self->{wheels} }) {
                next if $other->ID == $wheel->ID;
                $other->put($line);
            }
        }
    }
    elsif ($input->{command} eq 'WHO') {
        if ($input->{params}[0] && $input->{params}[0] !~ tr/*//) {
            if (!defined $input->{params}[1]) {
                if ($input->{params}[0] !~ /^[#&+!]/ || $irc->channel_list($input->{params}[0])) {
                    $state->enqueue(sub { $self->_put($wheel->ID, @_) }, 'who_reply', $input->{params}[0]);
                    return;
                }
            }
        }
    }
    elsif ($input->{command} eq 'MODE') {
        if ($input->{params}[0]) {
            my $mapping = $irc->isupport('CASEMAPPING');
            if (u_irc($input->{params}[0], $mapping) eq u_irc($irc->nick_name(), $mapping)) {
                if (!defined $input->{params}[1]) {
                    $wheel->put($state->mode_reply($input->{params}[0]));
                    return;
                }
            }
            elsif ($input->{params}[0] =~ /^[#&+!]/ && $irc->channel_list($input->{params}[0])) {
                if (!defined $input->{params}[1] || $input->{params}[1] =~ /^[eIb]$/) {
                    $state->enqueue(sub { $self->_put($wheel->ID, @_) }, 'mode_reply', @{ $input->{params} }[0,1]);
                    return;
                }
            }
        }
    }
    elsif ($input->{command} eq 'NAMES') {
        if ($irc->channel_list($input->{params}[0]) && !defined $input->{params}[1]) {
            $state->enqueue(sub { $self->_put($wheel->ID, @_) }, 'names_reply', $input->{params}[0]);
            return;
        }
    }
    elsif ($input->{command} eq 'TOPIC') {
        if ($irc->channel_list($input->{params}[0]) && !defined $input->{params}[1]) {
            $state->enqueue(sub { $self->_put($wheel->ID, @_) }, 'topic_reply', $input->{params}[0]);
            return;
        }
    }

    $irc->yield(quote => $input->{raw_line});

    return;
}

sub _drop_client {
    my ($self, $wheel_id) = @_[OBJECT, ARG0];
    my $irc = $self->{irc};

    if (delete $self->{wheels}{$wheel_id}) {
        $irc->send_event(irc_proxy_close => $wheel_id);
    }
    return;
}

sub S_raw {
    my ($self, $irc) = splice @_, 0, 2;
    my $raw_line = ${ $_[0] };
    return PCI_EAT_NONE if !keys %{ $self->{wheels} };

    my $input = $self->{ircd_filter}->get( [ $raw_line ] )->[0];
    return PCI_EAT_NONE if $input->{command} !~ /^(?:PING|PONG)/;
    $_->put($raw_line) for values %{ $self->{wheels} };
    return PCI_EAT_NONE;
}

sub _put {
    my ($self, $wheel_id, $raw_line) = @_;
    return if !defined $self->{wheels}{$wheel_id};
    $self->{wheels}{$wheel_id}->put($raw_line);
    return;
}

1;

=encoding utf8

=head1 NAME

POE::Compoent::IRC::Plugin::MultiProxy::ClientManager - A PoCo-IRC plugin which handles a proxy clients

=head1 SYNOPSIS

 use POE::Compoent::IRC::Plugin::MultiProxy::ClientManager;

 $irc->plugin_add('MultiProxyClient_1', POE::Compoent::IRC::Plugin::MultiProxy::Client->new());

=head1 DESCRIPTION

POE::Compoent::IRC::Plugin::MultiProxy::Client is a
L<POE::Component::IRC|POE::Component::IRC> plugin. It handles a input/output
and disconnects from a proxy client.

This plugin requires the IRC component to be
L<POE::Component::IRC::State|POE::Component::IRC::State> or a subclass thereof.

=head1 METHODS

=head2 C<new>

Takes no arguments. Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add()> method.

=head2 C<add_client>

Takes one argument, the socket of the new proxy client.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut
