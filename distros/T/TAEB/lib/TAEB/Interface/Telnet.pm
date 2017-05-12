package TAEB::Interface::Telnet;
use TAEB::OO;
use IO::Socket::Telnet;
use Errno;

=head1 NAME

TAEB::Interface::Telnet - how TAEB talks to nethack.alt.org

=cut

extends 'TAEB::Interface';

has server => (
    is      => 'ro',
    isa     => 'Str',
    default => 'nethack.alt.org',
);

has port => (
    is      => 'ro',
    isa     => 'Int',
    default => 23,
);

has account => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has password => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has socket => (
    is  => 'rw',
    isa => 'IO::Socket::Telnet',
);

has sent_login => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub BUILD {
    my $self = shift;

    TAEB->log->interface("Connecting to " . $self->server . ".");

    # this has to be done in BUILD because it needs server
    my $socket = IO::Socket::Telnet->new(
        PeerAddr => $self->server,
        PeerPort => $self->port,
    );

    die "Unable to connect to " . $self->server . ": $!"
        if !defined($socket);

    $socket->telnet_simple_callback(\&telnet_negotiation);
    $self->socket($socket);

    TAEB->log->interface("Connected to " . $self->server . ".");
}

=head2 read -> STRING

This will read from the socket. It will die if an error occurs.

It will return the input read from the socket.

This uses a method developed for nhbot that ensures that we've received all
output for our command before returning. Just before reading, it sends the
telnet equivalent of a PING. It then reads all input until it gets a PONG. the
idea is that the PING comes after all NH commands, so the PONG must come after
all the output of all the NH commands. The code looking for the PONG is in
the telnet complex callback.

The actual ping it uses is to send IAC DO chr(99), which is a nonexistent
option. Some servers may stop responding after the first IAC DO chr(99), so
it's kind of a bad hack. It used to be IAC SB STATUS SEND IAC SE but NAO
stopped paying attention to that. That last sentence was discovered over a few
hours of debugging. Yay.

=cut

augment read => sub {
    my $self = shift;
    my $buffer;

    $self->socket->do(chr(99));
    ${*{$self->socket}}{got_pong} = 0;

    eval {
        local $SIG{__DIE__};

        while (1) {
            my $b;
            defined $self->socket->recv($b, 4096, 0) and do {
                $buffer .= $b;
                die "alarm\n" if ${*{$self->socket}}{got_pong};
                next;
            };

            die "Disconnected from server: $!" unless $!{EINTR};
        }
    };

    die $@ if $@ !~ /^alarm\n/;

    if (!$self->sent_login && $buffer =~ /Not logged in\./) {
        print { $self->socket } join '', 'l',
                                         $self->account,  "\n",
                                         $self->password, "\n",
                                         '1', # for multi-game DGL
                                         'p';
        TAEB->log->interface("Logging in as " . $self->account);
        $self->sent_login(1);
    }

    return $buffer;
};

=head2 write STRING

This will write to the socket.

=cut

sub write {
    my $self = shift;
    my $text = shift;

    print {$self->socket} $text;
}

=head2 telnet_negotiation OPTION

This is a helper function used in conjunction with IO::Socket::Telnet. In
short, all nethack.alt.org expects us to answer affirmatively is TTYPE (to
which we respond xterm-color) and NAWS (to which we respond 80x24). Everything
else gets a response of DONT or WONT.

=cut

sub telnet_negotiation {
    my $self = shift;
    my $option = shift;

    if ($option =~ / 99$/) {
        ${*$self}{got_pong} = 1;
        return '';
    }

    TAEB->log->interface("Telnet negotiation: received $option");

    if ($option =~ /DO TTYPE/) {
        return join '',
               chr(255), # IAC
               chr(251), # WILL
               chr(24),  # TTYPE

               chr(255), # IAC
               chr(250), # SB
               chr(24),  # TTYPE
               chr(0),   # IS
               "xterm-color",
               chr(255), # IAC
               chr(240), # SE
    }

    if ($option =~ /DO NAWS/) {
        return join '',
               chr(255), # IAC
               chr(251), # WILL
               chr(31),  # NAWS

               chr(255), # IAC
               chr(250), # SB
               chr(31),  # NAWS
               chr(0),   # IS
               chr(80),  # 80
               chr(0),   # x
               chr(24),  # 24
               chr(255), # IAC
               chr(240), # SE
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

