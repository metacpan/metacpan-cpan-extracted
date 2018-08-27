package Net::Doveadm;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Doveadm - Dovecot’s administrative interface protocol

=head1 SYNOPSIS

    my $doveadm = Net::Doveadm->new(
        io => $io_object,

        # Required for authentication,
        # but we warn if the server doesn’t ask for them.
        username => $username,
        password => $password,
    );

    $doveadm->send(
        username => $cmd_username,
        command => [ $cmd, @args ],
    );

    my $result_ar;

    {
        # If using non-blocking I/O …
        # $io_object->flush_write_queue();

        last if $result_ar = $doveadm->receive();

        # If using non-blocking I/O, put a select(), poll(),
        # or similar call here.

        redo;
    }

=head1 DESCRIPTION

This module implements client logic for the
L<Doveadm protocol|https://wiki.dovecot.org/Design/DoveadmProtocol>,
which facilitates administrative communication with a
L<Dovecot|http://dovecot.org> server via TCP or a local socket.

Note that this is the original Doveadm protocol, not
L<the newer, HTTP-based one|https://wiki.dovecot.org/Design/DoveadmProtocol/HTTP>.

=head1 I/O

This module is designed, rather than to interact directly with a socket or
other filehandle, to use L<IO::Framed> as an abstraction over
the transmission medium. If so desired, a compatible interface can be
substituted for L<IO::Framed>; in particular, the interface must implement
L<IO::Framed>’s C<write()> and C<read_until()> methods.

If you use L<IO::Framed>, you should B<not> enable its C<allow_empty_read()>
mode. The Doveadm protocol is strictly RPC-oriented, and the only
successful end to a session is one that the client terminates.

Note that blocking and non-blocking I/O work nearly the same way;
the SYNOPSIS above demonstrates the difference. A particular feature of
this setup is that it’s possible to send multiple successive requests before
reading responses to those requests.

=head1 ERRORS

All errors that this module throws are instances of L<Net::Doveadm::X::Base>.
At this time, further details are subject to change.

=cut

#----------------------------------------------------------------------

use Net::Doveadm::X;

our $VERSION = '0.01';

our $DEBUG = 0;

use constant _LF => "\x0a";

=head1 METHODS

=head2 I<CLASS->new( %OPTS )

Instantiates this class. %OPTS are:

=over

=item * C<io> - An instance of L<IO::Framed> or a compatible interface.

=item * C<username> - The username to use in authentication. Required if
the server asks for it; if given and the server does not ask for it, a
warning is given.

=item * C<password> - As with C<username>.

=back

Note that no I/O happens in this method.

=cut

sub new {
    my ($class, %opts) = @_;

    $opts{"_$_"} = delete $opts{$_} for keys %opts;
    $opts{'_requests'} = [];

    return bless \%opts, $class;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->send( %OPTS )

Send (or enqueue the sending of) a command. %OPTS are:

=over

=item * C<command> - An array reference whose contents are (in order)
the command name and all arguments to the command. Note that some calls,
e.g., C<mailbox list>, are “compound commands” rather than a command with
argument.

=item * C<username> - Optional, the username to send with the command.

=item * C<verbosity> - Optional, either C<1> (“verbose”) or C<2> (“debug”).

=back

Note that, if the server handshake is not yet complete, this will
attempt to finish that before actually sending a message.

=cut

sub send {
    my ($self, %opts) = @_;

    my $flags = q<>;
    if ($opts{'verbosity'}) {
        if ($opts{'verbosity'} eq '1') {
            $flags = 'v';
        }
        elsif ($opts{'verbosity'} eq '2') {
            $flags = 'D';
        }
        else {
            die Net::Doveadm::X->create('Generic', "Invalid “verbosity”: “$opts{'verbosity'}”");
        }
    }

    _validate_command_pieces( $opts{'username'}, $opts{'command'} );

    if ( !defined $opts{'username'} ) {
        $opts{'username'} = q<>;
    }

    push @{ $self->{'_requests'} }, [ $flags, $opts{'username'}, @{ $opts{'command'} } ];

    if (!$self->{'_handshake_done'}) {
        return $self if !$self->_do_handshake();
    }

    $self->_flush_request_queue();

    return $self;
}

sub _validate_command_pieces {
    my ($username, $command_ar) = @_;

    for my $piece ($username, @$command_ar) {
        if ($piece =~ tr<\t\x0a><>) {
            die Net::Doveadm::X->create('Generic', "Invalid string in command: “$piece”");
        }
    }

    return;
}

#----------------------------------------------------------------------

=head2 $RESULT = I<OBJ>->receive()

Looks for a response to a previously-sent command. If such a response is
ready,
it will be returned as an array reference; otherwise, undef is returned.

Note that, if the server handshake is not yet complete, this will
attempt to finish that before actually trying to retrieve a message.

=cut

sub receive {
    my ($self) = @_;

    if (!$self->{'_handshake_done'}) {
        return undef if !$self->_do_handshake();

        # If we just finished the handshake, then send any pending requests
        # before we see about responses to them.
        $self->_flush_request_queue();
    }

    if ( !@{ $self->{'_requests'} } && !$self->{'_sent_requests'} ) {
        die Net::Doveadm::X->create('Generic', "No requests pending!");
    }

    $self->{'_line1'} ||= $self->_read_line() or return undef;

    $self->{'_line2'} ||= $self->_read_line() or return undef;

    $self->{'_sent_requests'}--;

    my ($line1, $line2) = delete @{$self}{'_line1', '_line2'};

    if ($line2 ne '+') {
        die Net::Doveadm::X->create('Response', "Error: $line2 ($line1)");
    }

    return [ split m<\t>, $line1, -1 ];
}

#----------------------------------------------------------------------

sub _flush_request_queue {
    my ($self) = @_;

    while ($self->_write($self->{'_requests'}[0])) {
        shift @{ $self->{'_requests'} };
        $self->{'_sent_requests'}++;
    }

    return;
}

sub _do_handshake {
    my ($self) = @_;

    if (!$self->{'_sent_hello'}) {
        $self->_write( [ 'VERSION', 'doveadm-server', 1, 0 ] );
        $self->{'_sent_hello'} = 1;
        return undef;
    }

    $self->{'_received_hello'} ||= $self->_read_line() or return undef;

    if ($self->{'_received_hello'} eq '+') {
        $self->{'_handshake_done'} = 1;

        for my $key ( qw( username  password ) ) {
            if ($self->{"_$key"}) {
                warn "“$key” submitted, but server says unneeded.";
            }
        }
    }
    elsif ($self->{'_received_hello'} eq '-') {

        if (!$self->{'_authn_sent'}) {
            $self->_send_authn();

            $self->{'_authn_sent'} = 1;

            return undef;
        }

        $self->{'_received_authn'} ||= $self->_read_line() or return undef;

        if ($self->{'_received_authn'} eq '+') {

            $self->{'_handshake_done'} = 1;
        }
        else {
            die Net::Doveadm::X->create('Authn', "Failed authn: “$self->{'_received_authn'}”");
        }
    }

    return 1;
}

sub _send_authn {
    my ($self) = @_;

    for my $key ( qw( username  password ) ) {
        if (!length $self->{"_$key"}) {
            die Net::Doveadm::X->create('Generic', "“$key” not submitted, but server says needed!");
        }
    }

    require MIME::Base64;
    my $authn_b64 = MIME::Base64::encode_base64("\0" . $self->{'_username'} . "\0" . $self->{'_password'});
    chop $authn_b64;

    $self->_write( [ 'PLAIN', $authn_b64 ] );

    return;
}

sub _write {
    my ($self, $pieces_ar) = @_;

    $DEBUG && print "$$ doveadm enqueue send: [@$pieces_ar]\n";

    return $self->{'_io'}->write( join("\t", @$pieces_ar ) . _LF() );
}

my $line_sr;

sub _read_line {
    my ($self) = @_;

    $line_sr = \$self->{'_io'}->read_until(_LF());

    # We never need the trailing LF.
    chop $$line_sr if $$line_sr;

    if ($DEBUG) {
        if ($$line_sr) {
            printf "$$ doveadm received: [$$line_sr]\n";
            return $$line_sr;
        }
        else {
            printf "$$ no line yet fully received\n";
        }
    }

    return $$line_sr;
}

#----------------------------------------------------------------------

=head1 REPOSITORY

L<https://github.com/FGasper/p5-Net-Doveadm>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 COPYRIGHT

Copyright 2018 by L<Gasper Software Consulting|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.

=cut

1;
