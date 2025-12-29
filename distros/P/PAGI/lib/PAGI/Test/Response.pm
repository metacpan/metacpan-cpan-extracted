package PAGI::Test::Response;

use strict;
use warnings;


sub new {
    my ($class, %args) = @_;
    return bless {
        status    => $args{status} // 200,
        headers   => $args{headers} // [],
        body      => $args{body} // '',
        exception => $args{exception},
    }, $class;
}

# Status code
sub status { shift->{status} }

# Raw body bytes
sub content { shift->{body} }

# Decoded text (alias for now, charset handling later)
sub text { shift->{body} }

# Header lookup (case-insensitive)
sub header {
    my ($self, $name) = @_;
    $name = lc($name);
    for my $pair (@{$self->{headers}}) {
        return $pair->[1] if lc($pair->[0]) eq $name;
    }
    return undef;
}

# All headers as hashref (last value wins for duplicates)
sub headers {
    my ($self) = @_;
    my %h;
    for my $pair (@{$self->{headers}}) {
        $h{lc($pair->[0])} = $pair->[1];
    }
    return \%h;
}

# Status helpers
sub is_success  { my $s = shift->status; $s >= 200 && $s < 300 }
sub is_redirect { my $s = shift->status; $s >= 300 && $s < 400 }
sub is_error    { my $s = shift->status; $s >= 400 }

# Exception from app (if trapped)
sub exception { shift->{exception} }

# Parse body as JSON
sub json {
    my ($self) = @_;
    require JSON::MaybeXS;
    return JSON::MaybeXS::decode_json($self->{body});
}

# Convenience header shortcuts
sub content_type   { shift->header('content-type') }
sub content_length { shift->header('content-length') }
sub location       { shift->header('location') }

1;

__END__

=head1 NAME

PAGI::Test::Response - HTTP response wrapper for testing

=head1 SYNOPSIS

    use PAGI::Test::Client;

    my $client = PAGI::Test::Client->new(app => $app);
    my $res = $client->get('/');

    # Status
    say $res->status;        # 200
    say $res->is_success;    # true

    # Headers
    say $res->header('Content-Type');  # 'application/json'
    say $res->headers->{location};     # for redirects

    # Body
    say $res->content;       # raw bytes
    say $res->text;          # decoded text
    say $res->json->{key};   # parsed JSON

=head1 DESCRIPTION

PAGI::Test::Response wraps HTTP response data from test requests,
providing convenient accessors for status, headers, and body content.

=head1 CONSTRUCTOR

=head2 new

    my $res = PAGI::Test::Response->new(
        status  => 200,
        headers => [['content-type', 'text/plain']],
        body    => 'Hello',
    );

Creates a new response object. Typically you don't call this directly;
it's created by L<PAGI::Test::Client> methods.

=head1 STATUS METHODS

=head2 status

    my $code = $res->status;

Returns the HTTP status code (e.g., 200, 404, 500).

=head2 is_success

    if ($res->is_success) { ... }

True if status is 2xx.

=head2 is_redirect

    if ($res->is_redirect) { ... }

True if status is 3xx.

=head2 is_error

    if ($res->is_error) { ... }

True if status is 4xx or 5xx.

=head2 exception

    if (my $err = $res->exception) {
        like $err, qr/Can't call method/;
    }

Returns the exception that was thrown by the application, if any.
This is only populated when the test client traps an exception
(the default behavior). See L<PAGI::Test::Client/raise_app_exceptions>.

Returns undef if no exception occurred.

=head1 HEADER METHODS

=head2 header

    my $value = $res->header('Content-Type');

Returns the value of a header. Case-insensitive lookup.
Returns undef if header not present.

=head2 headers

    my $hashref = $res->headers;

Returns all headers as a hashref. Header names are lowercased.
If a header appears multiple times, the last value wins.

=head1 BODY METHODS

=head2 content

    my $bytes = $res->content;

Returns the raw response body as bytes.

=head2 text

    my $string = $res->text;

Returns the response body decoded as text. Uses the charset
from Content-Type header if present, otherwise assumes UTF-8.

=head2 json

    my $data = $res->json;

Parses the response body as JSON and returns the data structure.
Dies if the body is not valid JSON.

=head1 CONVENIENCE METHODS

=head2 content_type

    my $ct = $res->content_type;

Shortcut for C<< $res->header('content-type') >>.

=head2 content_length

    my $len = $res->content_length;

Shortcut for C<< $res->header('content-length') >>.

=head2 location

    my $url = $res->location;

Shortcut for C<< $res->header('location') >>. Useful for redirects.

=head1 SEE ALSO

L<PAGI::Test::Client>

=cut
