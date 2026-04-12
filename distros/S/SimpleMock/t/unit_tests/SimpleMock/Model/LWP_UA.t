# Tests for SimpleMock::Model::LWP_UA
# Covers: GET/POST/PUT mocking, arg matching, bespoke responses, layer traversal
use strict;
use warnings;
use Test::Most;
use SimpleMock qw(register_mocks);
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;

register_mocks(

    LWP_UA => {

        'http://example.com' => {

            'GET' => [
                # static request with simple response
                # currently this is also used as the default response for
                # unmatched args to simplify the interface
                { response => 'Response for GET request with no args' },

                # request with args and simple response
                { args     => { foo => 'bar' },
                  response => 'Response for GET request with args',
                },

                # request with args and bespoke response
                { args => { foo2 => 'bar2' },
                  response => {
                      code => 404,
                      message => "Can't find it, dammit!",
                      headers => {
                          'x-response-test' => 'foo',
                      }
                  }
                },
            ],

            'POST' => [
                { args     => { foo3 => 'bar3' },
                  response => 'Response for POST request with args',
                }
            ],

        },
    }

);

my $r1 = $ua->get('http://example.com');
isa_ok($r1, 'HTTP::Response', 'HTTP::Response object created');
is $r1->content, 'Response for GET request with no args', 'GET request with no args';

my $r2 = $ua->get('http://example.com?foo=bar');
is $r2->content, 'Response for GET request with args', 'GET request with QS args';

my $r3 = $ua->get('http://example.com?foo2=bar2');
is $r3->content, '', "Bespoke response - content";
is $r3->code, 404, "Bespoke response - code";
is $r3->message, "Can't find it, dammit!", "Bespoke response - message";
my $header = $r3->header('x-response-test');
is $header, 'foo', "Bespoke response - header";

my $r4 = $ua->post('http://example.com', {
            foo3 => 'bar3'
         });
is $r4->content, 'Response for POST request with args', "POST request with args";

my $r5 = $ua->get('http://example.com?foo3=bar3');
is $r5->content, $r1->content, "GET request with unmatched args uses default";

throws_ok { $ua->get('http://not-mocked.example.com') }
    qr/No mock is defined/,
    'die on completely unmocked URL';

throws_ok { $ua->post('http://example.com', { foo => 'bar' }) }
    qr/No mock is defined/,
    'die on unmocked method for a mocked URL';

################################################################################
# Branch coverage for method fallthrough and layer traversal
################################################################################

# PUT request - falls through POST/GET branches, args treated as empty (_default sha)
register_mocks(
    LWP_UA => {
        'http://example.com/put-test' => {
            'PUT' => [
                { response => 'PUT response' },
            ],
        },
    },
);
my $r_put = $ua->put('http://example.com/put-test');
is $r_put->content, 'PUT response', 'PUT request returns mocked response';

# scoped layer with no LWP_UA key - _get_mock_for must traverse past it
{
    my $guard = SimpleMock::register_mocks_scoped();  # empty layer, no LWP_UA key
    my $r = $ua->get('http://example.com');
    is $r->content, 'Response for GET request with no args',
        '_get_mock_for traverses past scoped layer without LWP_UA key';
}

done_testing();
