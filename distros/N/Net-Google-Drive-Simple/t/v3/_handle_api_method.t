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
      http_json
    >,
);

my $gd_test = Test::MockModule->new('Net::Google::Drive::Simple::V3');

my @called;
$gd_test->redefine( 'init' => sub { push @called, 'init' } );

subtest(
    'Complex checks from info' => sub {
        @called = ();

        $gd_test->redefine(
            'http_json' => sub {
                my ( $self, $uri, $http_opts ) = @_;

                push @called, 'http_json';
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
            'http_json' => sub {
                my ( $self, $uri, $http_opts ) = @_;

                push @called, 'http_json';

                isa_ok( $uri, 'URI' );
                is(
                    $uri->as_string(),
                    "$gd->{'api_base_url'}test?foo=10",
                    'Correct GET URI',
                );

                is( $http_opts->[0], 'GET', 'Correct HTTP method' );

                is(
                    $http_opts->[1], undef,
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
            '_handle_api_method() returned values from http_json()',
        );

        is(
            \@called, [qw< init http_json >],
            'init() and http_json() were called',
        );
    }
);

subtest(
    'Body-based requests (POST/PATCH)' => sub {
        foreach my $http_method (qw< POST PATCH >) {
            @called = ();

            $gd_test->redefine(
                'http_json' => sub {
                    my ( $self, $uri, $http_opts ) = @_;

                    push @called, 'http_json';

                    isa_ok( $uri, 'URI' );
                    is(
                        $uri->as_string(),
                        "$gd->{'api_base_url'}test?foo=10",
                        "Correct $http_method URI",
                    );

                    is(
                        $http_opts->[0], $http_method,
                        'Correct HTTP method'
                    );

                    is(
                        $http_opts->[1],
                        { 'bar' => 'bar_value' },
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
                '_handle_api_method() returned values from http_json()',
            );

            is(
                \@called, [qw< init http_json >],
                'init() and http_json() were called',
            );
        }
    }
);

subtest(
    'Parameter-less request (DELETE)' => sub {
        @called = ();

        $gd_test->redefine(
            'http_json' => sub {
                my ( $self, $uri, $http_opts ) = @_;

                push @called, 'http_json';

                isa_ok( $uri, 'URI' );
                is(
                    $uri->as_string(),
                    "$gd->{'api_base_url'}test",
                    'Correct DELETE URI',
                );

                is( $http_opts->[0], 'DELETE', 'Correct HTTP method' );

                is(
                    $http_opts->[1],
                    undef,
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
            '_handle_api_method() returned values from http_json()',
        );

        is(
            \@called, [qw< init http_json >],
            'init() and http_json() were called',
        );
    }
);

done_testing();
