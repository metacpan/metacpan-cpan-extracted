package Test::SolusVM::Client;

use v5.36;
use warnings FATAL => 'all';
use re '/aa';

use Cpanel::JSON::XS ();
use Exporter         qw{import};
use Test::MockModule ();

# ABSTRACT: A SolusVM management node that is not there

=head1 SYNOPSIS

    use Test::SolusVM::Client qw{:all};

    my $mock = mock_http_tiny();
    mock_request( 'GET /api/v1/servers', json_response( { data => [] } ) );

    my $client = SolusVM::Client->new( host => 'solus.test', token => 'sekrit' );
    $client->get_list_of_servers();

    is( last_http_request(), 'GET https://solus.test/api/v1/servers', 'asked the right thing' );

=head1 DESCRIPTION

Intercepts L<HTTP::Tiny/request>, which is the bottom of L<SolusVM::Client>, so
that everything above it -- the generated methods, the query string, the body,
the token -- is exercised for real and only the network is imaginary.

A request nobody registered is fatal rather than forwarded.  A test that reaches
a real management node by accident is a test that passes for the wrong reason,
and on somebody else's machine it is one that hangs.

=cut

our @EXPORT_OK = qw{
  mock_http_tiny mock_request clear_mocks json_response
  last_http_request last_http_content last_http_headers http_requests
};
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my %MOCKED;
my @REQUESTS;

=func mock_http_tiny

Returns the L<Test::MockModule> standing in for L<HTTP::Tiny>.  Keep it in a
lexical: when it goes out of scope the real one comes back, which is what you
want between one subtest and the next.

=cut

sub mock_http_tiny {
    clear_mocks();

    my $mock = Test::MockModule->new('HTTP::Tiny');
    $mock->redefine( request => \&_answer );

    return $mock;
}

=func mock_request

    mock_request( 'POST /api/v1/auth/login', json_response( { data => {} } ) );
    mock_request( 'GET /api/v1/servers', sub ( $method, $url, $args ) { ... } );

Registers what to answer for a verb and path.  The path is matched without its
query string, so one registration serves every page of a listing; a coderef gets
the request and can answer differently each time, which is how paging and
token expiry get tested.

=cut

sub mock_request ( $what, $response ) {
    $MOCKED{$what} = $response;
    return $response;
}

=func json_response

    json_response( { data => [] } );
    json_response( { message => 'Unauthenticated.' }, status => 401, reason => 'Unauthorized' );

Builds the hashref L<HTTP::Tiny> would have returned, with the document encoded
as JSON.  Defaults to a 200.

=cut

sub json_response ( $document, %options ) {
    my $status = $options{status} // 200;

    return {
        status  => $status,
        reason  => $options{reason} // ( $status == 200 ? 'OK' : 'Error' ),
        success => ( $status >= 200 && $status < 300 ) ? 1 : 0,
        headers => { 'content-type' => 'application/json' },
        content => Cpanel::JSON::XS->new->utf8->canonical->encode($document),
    };
}

=func last_http_request

=func last_http_content

=func last_http_headers

The verb and URL of the most recent request as one string, the body it carried,
and the headers it was sent with.  Asserting on these is how a test says what was
sent rather than only what came back.

=cut

sub last_http_request { return @REQUESTS ? "$REQUESTS[-1]{method} $REQUESTS[-1]{url}" : undef }
sub last_http_content { return @REQUESTS ? $REQUESTS[-1]{content}                     : undef }
sub last_http_headers { return @REQUESTS ? $REQUESTS[-1]{headers}                     : undef }

=func http_requests

Every request so far, oldest first, each a hashref of C<method>, C<url>,
C<content> and C<headers>.  For the tests that care how many times something
happened, and in what order.

=cut

sub http_requests { return @REQUESTS }

=func clear_mocks

Forgets both the registrations and the record of what was asked.

=cut

sub clear_mocks {
    %MOCKED   = ();
    @REQUESTS = ();
    return 1;
}

sub _answer ( $self, $method, $url, $args = {} ) {
    push @REQUESTS, {
        method  => $method,
        url     => $url,
        content => $args->{content},
        headers => $args->{headers} // {},
    };

    my $path = $url;
    $path =~ s{^[a-z]+://[^/]+}{};
    $path =~ s/[?].*$//;

    my $response = $MOCKED{"$method $path"};
    die "Nothing is mocked for $method $path, and this test is not allowed out onto the network.\n" unless $response;

    return ref $response eq 'CODE' ? $response->( $method, $url, $args ) : $response;
}

1;
