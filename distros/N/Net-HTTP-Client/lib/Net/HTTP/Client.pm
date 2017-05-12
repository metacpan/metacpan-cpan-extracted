package Net::HTTP::Client;
$Net::HTTP::Client::VERSION = '0.012';
use 5.10.0;
use strict;
use warnings;

use Errno qw(EINTR EIO :POSIX);
use HTTP::Response;

use parent qw/Net::HTTP/;

my $DEBUG = 0;
my $used = 0;

sub new {
    my $class = shift;
    $class->SUPER::new(@_);
}

sub request {
    my ($self, $method, $uri, @headers) = @_;

    my $content = (@headers % 2) ? pop @headers : '';

    if ($uri !~ /^\//) {
        my $host;
        ($host, $uri) = split /\//, $uri, 2;
        warn "New connection to host $host\n" if $DEBUG;
        $self = $self->new(Host => $host) || die $@;
        $uri = '/' . ($uri // '');
    } elsif ($used and !$self->keep_alive // 0) {
        warn 'Reconnecting to ', $self->peerhost, ':', $self->peerport, "\n" if $DEBUG;
        $self = $self->new(Host => $self->peerhost, PeerPort => $self->peerport) || die $@;
    }
    $used = 1;
    warn "$method $uri\n" if $DEBUG;

    my $success = $self->print( $self->format_request($method => $uri, @headers, $content) );
    my ($status, $message, @res_headers) = $self->read_response_headers;
    HTTP::Response->new($status, $message, \@res_headers, $self->get_content());
}

sub get_content {
    my ($self) = @_;
    my $content = '';
    while (1) {
        my $buf;
        my $n = $self->read_entity_body($buf, 1024);
        die "read failed: $!" unless defined $n or $!{EINTR} or $!{EAGAIN};
        last unless $n;
        $content .= $buf;
    }
    $content;
}

1;

__END__

=head1 NAME

Net::HTTP::Client - A Not-quite-so-low-level HTTP connection (client)

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  use Net::HTTP::Client;

  my $client = Net::HTTP::Client->new(Host => 'localhost', KeepAlive => 0);

  my $res = $client->request(POST => '/foo', 'fizz buzz');

  if ($res->is_success) {
    print $res->decoded_content;
  } else {
    warn $res->status_line, "\n";
  }

  # a new connection to www.example.com
  $res = $client->request(GET => 'www.example.com');

  # another connection to www.example.com
  $res = $client->request(GET => 'www.example.com/foo');

  # a new connection to localhost:3335
  $res = $client->request(GET => 'localhost/bar');

  # original connection to localhost:3335 IFF KeepAlive is set, otherwise a new connection
  $res = $client->request(POST => '/baz', 'foo');


  # or you can skip calling new()
  $res = Net::HTTP::Client->request(POST => 'localhost:3335/foo', 'Content-Type' => 'application/x-www-form-urlencoded', 'foo=fizz+buzz');

=head1 DESCRIPTION

B<Net::HTTP::Client> provides a simple interface to L<Net::HTTP>, and is a
sub-class of it.

This was written because I wanted something that did less than what
L<LWP::UserAgent> does when making requests.  Like L<LWP::UserAgent>, it
returns an L<HTTP::Response> object, so you can handle the response just the
same.

=over 2

=item new(%options)

The B<Net::HTTP::Client> constructor method takes the same options as
L<Net::HTTP>, with the same requirements.

=item request($method, $uri, @headers?, $content?)

Sends a request with method B<$method> and path B<$uri>. Key-value pairs of
B<@headers> and B<$content> are optional.  If B<KeepAlive> is set at
B<new()>, multiple calls to this will use the same connection.  Otherwise, a
new connection will be created automatically.  In addition, a B<$uri> may
contain a different host and port, in which case it will make a new
connection.  For convenience, if you don't wish to reuse connections, you
may call this method directly without invoking B<new()> if B<$uri> contains
a host.

Returns an L<HTTP::Response> object.

=item get_content()

Reads and returns the body content of the response. This is called by
B<request()>, so don't use this if using that.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ashley Willis E<lt>ashley+perl@gitable.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Net::HTTP>

L<LWP::UserAgent>
