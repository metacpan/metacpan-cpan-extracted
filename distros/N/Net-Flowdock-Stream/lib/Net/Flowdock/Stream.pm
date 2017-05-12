package Net::Flowdock::Stream;
BEGIN {
  $Net::Flowdock::Stream::AUTHORITY = 'cpan:DOY';
}
{
  $Net::Flowdock::Stream::VERSION = '0.01';
}
use Moose;
# ABSTRACT: Streaming API for Flowdock

use JSON;
use MIME::Base64;
use Net::HTTPS::NB;



has token => (
    is  => 'ro',
    isa => 'Str',
);


has email => (
    is  => 'ro',
    isa => 'Str',
);


has password => (
    is  => 'ro',
    isa => 'Str',
);


has flows => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        flows => 'elements',
    },
);

has socket_timeout => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.01,
);

has debug => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has _socket => (
    is  => 'rw',
    isa => 'Net::HTTPS::NB',
);

has _readbuf => (
    traits  => ['String'],
    is      => 'rw',
    isa     => 'Str',
    default => '',
    handles => {
        _append_readbuf => 'append',
    },
);

has _events => (
    is      => 'rw',
    isa     => 'ArrayRef[HashRef]', # XXX make these into objects
    default => sub { [] },
);

sub BUILD {
    my $self = shift;

    my $auth;
    if (my $token = $self->token) {
        $auth = $token;
    }
    elsif (my ($email, $pass) = ($self->email, $self->password)) {
        $auth = "$email:$pass";
    }
    else {
        die "You must supply either your token or your email and password";
    }

    my $s = Net::HTTPS::NB->new(Host => 'stream.flowdock.com');
    my $flows = join(',', $self->flows);
    $s->write_request(
        GET => "/flows?filter=$flows" =>
        Authorization => 'Basic ' . MIME::Base64::encode($auth),
        Accept        => 'application/json',
    );

    my ($code, $message, %headers) = $s->read_response_headers;
    die "Unable to connect: $message"
        unless $code == 200;

    $self->_socket($s);
}


sub get_next_event {
    my $self = shift;

    return unless $self->_socket_is_readable;

    $self->_read_next_chunk;

    return $self->_process_readbuf;
}

sub _socket_is_readable {
    my $self = shift;

    my ($rin, $rout) = ('');
    vec($rin, fileno($self->_socket), 1) = 1;

    my $res = select($rout = $rin, undef, undef, $self->socket_timeout);

    if ($res == -1) {
        return if $!{EAGAIN} || $!{EINTR};
        die "Error reading from socket: $!";
    }

    return if $res == 0;

    return 1 if $rout;

    return;
}

sub _read_next_chunk {
    my $self = shift;

    my $nbytes = $self->_socket->read_entity_body(my $buf, 4096);
    if (!defined $nbytes) {
        return if $!{EINTR} || $!{EAGAIN};
        die "Error reading from server";
    }
    die "Disconnected" if $nbytes == 0;
    return if $nbytes == -1;

    $self->_append_readbuf($buf);
}

sub _process_readbuf {
    my $self = shift;

    if ((my $buf = $self->_readbuf) =~ s/^([^\x0d]*)\x0d//) {
        my $chunk = $1;
        $self->_readbuf($buf);
        warn "New event:\n$chunk" if $self->debug;
        return decode_json($chunk);
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__
=pod

=head1 NAME

Net::Flowdock::Stream - Streaming API for Flowdock

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $stream = Net::Flowdock::Stream->new(
      token => '...',
      flows => ['myorg/testing'],
  );

  while (1) {
      if (my $event = $stream->get_next_event) {
          process_event($event);
      }
  }

=head1 DESCRIPTION

This module implements the streaming api for
L<Flowdock|https://www.flowdock.com/>. It provides a non-blocking method which
you can call to get the next available event in the stream. You can then
integrate this method into your existing event-driven app.

=head1 ATTRIBUTES

=head2 token

Your account's API token, for authentication. Required unless C<email> and
C<password> are provided.

=head2 email

Your account's email address, for authentication. Required unless C<token> is
provided.

=head2 password

Your account's password, for authentication. Required unless C<token> is
provided.

=head2 flows

An arrayref of flows that should be listened to for events. Note that the flow
names must include the organization, so C<myorg/testing>, not just C<testing>.

=head1 METHODS

=head2 get_next_event

Returns the next event that has been received in the stream. This call is
nonblocking, and will return undef if no events are currently available.

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-net-flowdock-stream at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Flowdock-Stream>.

=head1 SEE ALSO

L<https://www.flowdock.com/>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Net::Flowdock::Stream

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Flowdock-Stream>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Flowdock-Stream>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Flowdock-Stream>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Flowdock-Stream>

=back

=for Pod::Coverage BUILD

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

