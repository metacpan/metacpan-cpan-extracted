package POE::Component::Server::IRC::Plugin::Auth;
BEGIN {
  $POE::Component::Server::IRC::Plugin::Auth::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::Server::IRC::Plugin::Auth::VERSION = '1.52';
}

use strict;
use warnings;
use Carp 'croak';
use POE;
use POE::Component::Client::Ident::Agent;
use POE::Component::Client::DNS;
use POE::Component::Server::IRC::Plugin 'PCSI_EAT_NONE';

sub new {
    my ($package, %args) = @_;
    return bless \%args, $package;
}

sub PCSI_register {
    my ($self, $ircd) = splice @_, 0, 2;

    $self->{ircd} = $ircd;

    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                resolve_hostname
                resolve_ident
                got_hostname
            )],
            $self => {
                ident_agent_reply => 'got_ident',
                ident_agent_error => 'got_ident_error',
            }
        ],
    );

    $ircd->plugin_register($self, 'SERVER', qw(connection));
    return 1;
}

sub PCSI_unregister {
    my ($self, $ircd) = splice @_, 0, 2;
    $self->{resolver}->shutdown() if $self->{resolver};
    return 1;
}

sub _start {
    my ($self, $session) = @_[OBJECT, SESSION];
    $self->{session_id} = $session->ID;

    $self->{resolver} = POE::Component::Client::DNS->spawn(
        Timeout => 10,
    );
    return;
}

sub IRCD_connection {
    my ($self, $ircd) = splice @_, 0, 2;
    pop @_;
    my ($conn_id, $peeraddr, $peerport, $sockaddr, $sockport, $needs_auth)
        = map { $$_ } @_;

    return PCSI_EAT_NONE if !$needs_auth;
    return PCSI_EAT_NONE if !$ircd->connection_exists($conn_id);

    $self->{conns}{$conn_id} = {
        hostname => '',
        ident    => '',
    };

    $ircd->send_output(
        {
            command => 'NOTICE',
            params  => ['AUTH', '*** Checking Ident'],
        },
        $conn_id,
    );

    $ircd->send_output(
        {
            command => 'NOTICE',
            params  => ['AUTH', '*** Checking Hostname'],
        },
        $conn_id,
    );

    if ($peeraddr =~ /^127\./) {
        $ircd->send_output(
            {
                command => 'NOTICE',
                params  => ['AUTH', '*** Found your hostname']
            },
            $conn_id,
        );
        $self->{conns}{$conn_id}{hostname} = 'localhost';
        $self->_auth_done($conn_id);
    }
    else {
        $poe_kernel->call(
            $self->{session_id}, 'resolve_hostname',
            $conn_id, $peeraddr,
        );
    }

    $poe_kernel->call(
        $self->{session_id}, 'resolve_ident',
        $conn_id, $peeraddr, $peerport, $sockaddr, $sockport,
    );

    return PCSI_EAT_NONE;
}

sub resolve_hostname {
    my ($self, $conn_id, $peeraddr) = @_[OBJECT, ARG0, ARG1];

    my $response = $self->{resolver}->resolve(
        event   => 'got_hostname',
        host    => $peeraddr,
        type    => 'PTR',
        context => {
            conn_id   => $conn_id,
            peeraddr => $peeraddr,
        },
    );

    $poe_kernel->call('got_hostname', $response) if $response;
    return;
}

sub resolve_ident {
    my ($kernel, $self, $conn_id, $peeraddr, $peerport, $sockaddr, $sockport)
        = @_[KERNEL, OBJECT, ARG0..$#_];

    POE::Component::Client::Ident::Agent->spawn(
        PeerAddr    => $peeraddr,
        PeerPort    => $peerport,
        SockAddr    => $sockaddr,
        SockPort    => $sockport,
        BuggyIdentd => 1,
        TimeOut     => 10,
        Reference   => $conn_id,
    );
    return;
}

sub got_hostname {
    my ($kernel, $self, $response) = @_[KERNEL, OBJECT, ARG0];
    my $conn_id = $response->{context}{conn_id};
    my $ircd    = $self->{ircd};

    if (!$ircd->connection_exists($conn_id)) {
        delete $self->{conns}{$conn_id};
        return;
    }

    my $fail = sub {
        $ircd->send_output(
            {
                command => 'NOTICE',
                params  => [
                    'AUTH',
                    "*** Couldn\'t look up your hostname",
                ],
            },
            $conn_id,
        );

        if ($self->{conns}{$conn_id}{done} == 2) {
            $self->_auth_done($conn_id);
        }
    };

    return $fail->() if !defined $response->{response};
    my @answers = $response->{response}->answer();
    return $fail->() if !@answers;

    for my $answer (@answers) {
        my $context = $response->{context};
        $context->{hostname} = $answer->rdatastr();

        chop $context->{hostname} if $context->{hostname} =~ /\.$/;
        my $query = $self->{resolver}->resolve(
            event   => 'got_ip',
            host    => $answer->rdatastr(),
            context => $context,
            type    => 'A',
        );
        if (defined $query) {
            $kernel->call($self->{session_id}, 'got_ip', $query);
        }
    }

    return;
}

sub got_ip {
    my ($kernel, $self, $response) = @_[KERNEL, OBJECT, ARG0];
    my $conn_id = $response->{context}{conn_id};
    my $ircd    = $self->{ircd};

    if (!$ircd->connection_exists($conn_id)) {
        delete $self->{conns}{$conn_id};
        return;
    }

    my $fail = sub {
        $ircd->send_output(
            {
                command => 'NOTICE',
                params  => [
                    'AUTH',
                    "*** Couldn't look up your hostname",
                ],
            },
            $conn_id,
        );
        $self->_auth_done($conn_id);
    };

    return $fail->() if !defined $response->{response};
    my @answers = $response->{response}->answer();
    return $fail->() if !@answers;

    my $peeraddress = $response->{context}{peeraddress};
    my $hostname    = $response->{context}{hostname};
    for my $answer (@answers) {
        if ($answer->rdatastr() eq $peeraddress) {
            $ircd->send_output(
                {
                    command => 'NOTICE',
                    params  => ['AUTH', '*** Found your hostname'],
                },
                $conn_id,
            );
            $self->{conns}{$conn_id}{hostname} = $hostname;
            $self->_auth_done($conn_id);
            return;
        }
    }

    $ircd->send_output(
        {
            command => 'NOTICE',
            params  => [
                'AUTH',
                '*** Your forward and reverse DNS do not match',
            ],
        },
        $conn_id,
    );
    $self->_auth_done($conn_id);
    return;
}

sub _auth_done {
    my ($self, $conn_id) = @_;

    $self->{conns}{$conn_id}{done}++;
    return if $self->{conns}{$conn_id}{done} != 2;

    my $auth = delete $self->{conns}{$conn_id};
    $self->{ircd}->send_event(
        'auth_done',
        $conn_id,
        {
            ident    => $auth->{ident},
            hostname => $auth->{hostname},
        },
    );
    return;
}

sub got_ident_error {
    my ($kernel, $self, $ref, $error) = @_[KERNEL, OBJECT, ARG0, ARG1];
    my $conn_id = $ref->{Reference};
    my $ircd = $self->{ircd};

    if (!$ircd->connection_exists($conn_id)) {
        delete $self->{conns}{$conn_id};
        return;
    }

    $ircd->send_output(
        {
            command => 'NOTICE',
            params  => ['AUTH', "*** No Ident response"],
        },
        $conn_id,
    );
    $self->_auth_done($conn_id);
    return;
}

sub got_ident {
    my ($kernel, $self, $ref, $opsys, $other)
        = @_[KERNEL, OBJECT, ARG0, ARG1, ARG2];
    my $conn_id = $ref->{Reference};
    my $ircd = $self->{ircd};

    if (!$ircd->connection_exists($conn_id)) {
        delete $self->{conns}{$conn_id};
        return;
    }

    my $ident = '';
    $ident = $other if uc $opsys ne 'OTHER';
    $ircd->send_output(
        {
            command => 'NOTICE',
            params  => ['AUTH', "*** Got Ident response"],
        },
        $conn_id,
    );
    $self->{conns}{$conn_id}{ident} = $ident;
    $self->_auth_done($conn_id);
    return;
}

1;

=encoding utf8

=head1 NAME

POE::Component::Server::IRC::Plugin::Auth - Authentication subsystem of POE::Component::Server::IRC::Backend

=head1 DESCRIPTION

This module is used internally by
L<POE::Component::Server::IRC::Backend|POE::Component::Server::IRC::Backend>.
No need for you to use it.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson <hinrik.sig@gmail.com>

Chris 'BinGOs' Williams

=cut
