use Test2::V0;
use Test2::Tools::Explain;
use Test2::Tools::Exception qw< dies >;
use Test2::Plugin::NoWarnings;
use Test::MockModule qw< strict >;
use Net::Google::Drive::Simple::V3;

my $gd = Net::Google::Drive::Simple::V3->new();
isa_ok( $gd, 'Net::Google::Drive::Simple::V3' );
can_ok(
    $gd,
    qw<
      _handle_api_method
      init
      _prepare_body_options
      _validate_param_type
      _handle_deprecated_params
      _handle_complex_types
      _generate_uri
      _make_request
    >,
);

my $gd_test = Test::MockModule->new('Net::Google::Drive::Simple::V3');

my @called;
$gd_test->redefine( 'init' => sub { push @called, 'init' } );

# We don't want to accidentally trigger oauth getting mad
# TODO: Move these headers till the request?
my $mock_oauth = Test::MockModule->new('OAuth::Cmdline');
if ( !$ENV{'LIVE_TEST'} ) {
    $mock_oauth->redefine( 'authorization_headers', sub { () } );
}

subtest(
    'Complex checks from info' => sub {
        @called = ();

        $gd_test->redefine(
            '_make_request' => sub {
                my ( $self, $uri, $http_opts ) = @_;

                push @called, '_make_request';
            },
        );

        my $info = {
            'path'             => 'test',
            'method_name'      => 'test_file',
            'http_method'      => 'GET',
            'query_parameters' => {
                'foo' => [ 'string',  0 ],
                'bar' => [ 'integer', 0 ],
            },

            'parameter_checks' => {
                'foo' => sub {
                    my $val = $_;
                    push @called, 'parameter_check_foo';
                    is( $val, 'baz', 'foo is baz in check' );
                    $val =~ /quux/xms
                      or return 'must be quux';
                    return 0;
                },

                'bar' => sub {
                    my $val = $_;
                    push @called, 'parameter_check_bar';
                    is( $val, 0, 'bar is 0 in check' );
                    $val =~ /^[0-9]+$/xms
                      or return 'integer';
                    return 0;
                },

                'abc' => sub {
                    push @called, 'parameter_check_abc';
                    die 'Should not get here';
                },
            },
        };

        my $options = { 'foo' => 'baz', 'bar' => 0 };

        like(
            dies( sub { $gd->_handle_api_method( $info, $options ) } ),
            qr/\Q[test_file] Parameter 'foo' failed validation: must be quux\E/,
            '_handle_api_method() failed for parameter check',
        );

        is(
            \@called,
            [qw< parameter_check_bar parameter_check_foo >],
            'checks were called but not init()',
        );
    }
);

subtest(
    'GET request' => sub {
        @called = ();

        $gd_test->redefine(
            '_make_request' => sub {
                my ( $self, $req ) = @_;

                push @called, '_make_request';

                isa_ok( $req, 'HTTP::Request' );
                is(
                    $req->uri(),
                    "$gd->{'api_base_url'}test?foo=10",
                    'Correct GET URI',
                );

                is( $req->method(), 'GET', 'Correct HTTP method' );

                is(
                    $req->content(),
                    '',
                    'No body parameters with a GET request',
                );

                return { 'key' => 'value' };
            }
        );

        my $info = {
            'path'             => 'test',
            'method_name'      => 'test_file',
            'http_method'      => 'GET',
            'query_parameters' => {
                'foo' => [ 'integer', 0 ],
            },
        };

        my $options = { 'foo' => 10 };

        is(
            $gd->_handle_api_method( $info, $options ),
            { 'key' => 'value' },
            '_handle_api_method() returned values from _make_request()',
        );

        is(
            \@called, [qw< init _make_request >],
            'init() and _make_request() were called',
        );
    }
);

subtest(
    'Body-based requests (POST/PATCH)' => sub {
        foreach my $http_method (qw< POST PATCH >) {
            @called = ();

            $gd_test->redefine(
                '_make_request' => sub {
                    my ( $self, $req ) = @_;

                    push @called, '_make_request';

                    isa_ok( $req, 'HTTP::Request' );
                    is(
                        $req->uri(),
                        "$gd->{'api_base_url'}test?foo=10",
                        "Correct $http_method URI",
                    );

                    is(
                        $req->method(),
                        $http_method,
                        'Correct HTTP method',
                    );

                    is(
                        $req->content(),
                        '{"bar":"bar_value"}',
                        "Got correct body parameters with a $http_method request",
                    );

                    return { 'key' => 'value' };
                }
            );

            my $info = {
                'path'             => 'test',
                'method_name'      => 'test_file',
                'http_method'      => $http_method,
                'query_parameters' => {
                    'foo' => [ 'integer', 0 ],
                },

                'body_parameters' => [qw< bar >],
            };

            my $options = { 'foo' => 10, 'bar' => 'bar_value' };

            is(
                $gd->_handle_api_method( $info, $options ),
                { 'key' => 'value' },
                '_handle_api_method() returned values from _make_request()',
            );

            is(
                \@called, [qw< init _make_request>],
                'init() and _make_request() were called',
            );
        }
    }
);

subtest(
    'Parameter-less request (DELETE)' => sub {
        @called = ();

        $gd_test->redefine(
            '_make_request' => sub {
                my ( $self, $req ) = @_;

                push @called, '_make_request';

                isa_ok( $req, 'HTTP::Request' );
                is(
                    $req->uri(),
                    "$gd->{'api_base_url'}test",
                    'Correct DELETE URI',
                );

                is( $req->method(), 'DELETE', 'Correct HTTP method' );

                is(
                    $req->content(),
                    '',
                    'No body parameters with a DELETE request',
                );

                return { 'key' => 'value' };
            }
        );

        my $info = {
            'path'        => 'test',
            'method_name' => 'test_file',
            'http_method' => 'DELETE',
        };

        my $options = {};

        is(
            $gd->_handle_api_method( $info, $options ),
            { 'key' => 'value' },
            '_handle_api_method() returned values from _make_request()',
        );

        is(
            \@called, [qw< init _make_request >],
            'init() and _make_request() were called',
        );
    }
);

done_testing();
