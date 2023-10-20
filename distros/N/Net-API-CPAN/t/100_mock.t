#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Changes::Version;
    use Module::Generic::File qw( file );
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'Net::API::CPAN::Mock' ) || BAIL_OUT( "Unable to load Net::API::CPAN::Mock" );
};

my $mock = Net::API::CPAN::Mock->new( debug => $DEBUG );
isa_ok( $mock => 'Net::API::CPAN::Mock' );
BAIL_OUT( Net::API::CPAN::Mock->error ) if( !defined( $mock ) );

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Mock.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$mock, ''$m'' );"'
can_ok( $mock, 'bind' );
can_ok( $mock, 'checksum' );
can_ok( $mock, 'data' );
can_ok( $mock, 'endpoints' );
can_ok( $mock, 'host' );
can_ok( $mock, 'json' );
can_ok( $mock, 'load_specs' );
can_ok( $mock, 'pid' );
can_ok( $mock, 'port' );
can_ok( $mock, 'pretty' );
can_ok( $mock, 'socket' );
can_ok( $mock, 'specs' );
can_ok( $mock, 'start' );
can_ok( $mock, 'stop' );
can_ok( $mock, 'url_base' );

my $rv;
my $me = file(__FILE__);
my $openapi_file = $me->parent->child( '../build/cpan-openapi-spec-3.0.0.json' );
diag( "OpenAPI file is $openapi_file" ) if( $DEBUG );
$rv = $mock->load_specs( $openapi_file ) || BAIL_OUT( $mock->error );
ok( $rv, 'load_specs' );
my $specs = $mock->specs;
# my $out_specs = file( 'dev/load_specs.pl' );
# diag( "Dumping processed specs" );
# require Data::Pretty;
# $out_specs->unload_perl( $specs, callback => sub{ Data::Pretty::dump( @_ ) } );

require HTTP::Promise::Request;
my( $req, $resp, $payload );
my $data = $mock->data;
my $users = [sort( keys( %{$data->{users}} ) )];
my $mods = [sort( keys( %{$data->{users}->{ $users->[0] }->{modules}} ) )];

# NOTE: testing mock core methods
ok( $mock->checksum, 'checksum' );
ok( $data, 'data' );
if( defined( $data ) )
{
    is( ref( $data ), 'HASH', 'data return an hash reference' );
    ok( scalar( keys( %$data ) ), 'has mock data loaded' );
}
$rv = $mock->endpoints;
isa_ok( $rv => 'Module::Generic::Hash', 'endpoints' );
$rv = $mock->json;
isa_ok( $rv => 'JSON', 'json' );
ok( !$mock->pretty, 'pretty by default is false' );
ok( $specs, 'specs' );
if( defined( $specs ) )
{
    is( ref( $specs ), 'HASH', 'specs returns an hash reference' );
    ok( scalar( keys( %$specs ) ), 'has specs loaded' );
}

# TODO: bind, host, pid, port, socket, start, stop, url_base
diag( "Binding socket for mock server." ) if( $DEBUG );
$rv = $mock->bind;
ok( $rv, 'bind' );
BAIL_OUT( "Unable to bind socket for mock server: ", $mock->error ) if( !defined( $rv ) );

ok( $mock->host, 'host' );
ok( $mock->port, 'port' );
ok( $mock->socket, 'socket' );

diag( "Starting mock server." ) if( $DEBUG );
$rv = $mock->start;
ok( $rv, 'start' );
BAIL_OUT( "Failed to start mock server: ", $mock->error ) if( !defined( $rv ) );
ok( $mock->pid, "pid -> " . ( $mock->pid // 'undef' ) );
$rv = $mock->url_base;
isa_ok( $rv => 'URI', 'url_base' );
ok( $mock->stop, 'stop' );
ok( !$mock->pid, 'no more pid' );

# NOTE: tests dictionary
my $tests =
{
    # NOTE: /v1/activity
    "/v1/activity" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/author
    "/v1/author" => {
        get => { query => "q=" . $users->[0] },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { pauseid => $users->[0] },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/author/_search
    "/v1/author/_search" => {
        get => { query => "q=" . $users->[0] },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { pauseid => $users->[0] },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/author/_search/scroll
    "/v1/author/_search/scroll" => {
        'delete' => {},
        get => { query => "q=" . $users->[0] . "&scroll=1m&scroll_id=something" },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { pauseid => $users->[0] },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/author/by_ids
    "/v1/author/by_ids" => {
        get => { query => "id=" . $users->[0] },
        post => {
            payload => sub{ $mock->json->utf8->encode({ id => $users->[0] }); },
        },
    },
    # NOTE: /v1/author/by_prefix/{prefix}
    "/v1/author/by_prefix/{prefix}" => {
        get => {
            vars => { prefix => substr( $users->[0], 0, 3 ) },
        },
        post => {
            vars => { prefix => substr( $users->[0], 0, 3 ) },
        },
    },
    # NOTE: /v1/author/by_user
    "/v1/author/by_user" => {
        get => { query => "user=" . $users->[0] },
        post => {
            payload => sub{ $mock->json->utf8->encode({ user => $users->[0] }); },
        },
    },
    # NOTE: /v1/author/by_user/{user}
    "/v1/author/by_user/{user}" => {
        get => {
            vars => { user => $data->{users}->{ $users->[0] }->{user} },
        },
        post => {
            vars => { user => $data->{users}->{ $users->[0] }->{user} },
        },
    },
    # NOTE: /v1/author/{author}
    "/v1/author/{author}" => {
        get => {
            vars => { author => $users->[0] },
        },
        post => {
            vars => { author => $users->[0] },
        },
    },
    # NOTE: /v1/changes/by_releases
    "/v1/changes/by_releases" => {
        get => {
            query => "release=" . $users->[0] . "/" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
        },
        post => {
            payload => sub{ $mock->json->utf8->encode({ release => $users->[0] . "/" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release} }); },
        },
    },
    # NOTE: /v1/changes/{author}/{release}
    "/v1/changes/{author}/{release}" => {
        get => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/changes/{distribution}
    "/v1/changes/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/contributor/by_pauseid/{author}
    "/v1/contributor/by_pauseid/{author}" => {
        get => {
            vars => { author => $users->[0] },
        },
        post => {
            vars => { author => $users->[0] },
        },
    },
    # NOTE: /v1/contributor/{author}/{release}
    "/v1/contributor/{author}/{release}" => {
        get => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/cover/{release}
    "/v1/cover/{release}" => {
        get => {
            vars => {
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/cve/dist/{distribution}
    "/v1/cve/dist/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/cve/release/{author}/{release}
    "/v1/cve/release/{author}/{release}" => {
        get => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/cve/{cpanid}
    "/v1/cve/{cpanid}" => {
        get => {
            vars => { cpanid => $users->[0] },
        },
    },
    # NOTE: /v1/diff/file/{file1}/{file2}
    "/v1/diff/file/{file1}/{file2}" => {
        get => {
            vars => {
                file1 => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{id},
                file2 => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[1] }->{id},
            },
        },
        post => {
            vars => {
                file1 => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{id},
                file2 => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[1] }->{id},
            },
        },
    },
    # NOTE: /v1/diff/release/{author1}/{release1}/{author2}/{release2}
    "/v1/diff/release/{author1}/{release1}/{author2}/{release2}" => {
        get => {
            vars => {
                author1 => $users->[0],
                author2 => $users->[0],
                release1 => do{ my @a=split( "-", $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release} ); my $v=Changes::Version->parse( $a[-1] ); $v--; join( "-", @a[0, -2], $v ) },
                release2 => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author1 => $users->[0],
                author2 => $users->[0],
                release1 => do{ my @a=split( "-", $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release} ); my $v=Changes::Version->parse( $a[-1] ); $v--; join( "-", @a[0, -2], $v ) },
                release2 => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/diff/release/{distribution}
    "/v1/diff/release/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/distribution
    "/v1/distribution" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/distribution/river
    "/v1/distribution/river" => {
        get => {
            query => "distribution=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
        },
        post => {
            payload => sub{ $mock->json->utf8->encode({ distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} }); },
        },
    },
    # NOTE: /v1/distribution/river/{distribution}
    "/v1/distribution/river/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/distribution/{distribution}
    "/v1/distribution/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/distribution/_search
    "/v1/distribution/_search" => {
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { name => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/distribution/_search/scroll
    "/v1/distribution/_search/scroll" => {
        'delete' => {},
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} . "&scroll=1m&scroll_id=something" },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { name => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/download_url/{module}
    "/v1/download_url/{module}" => {
        get => {
            vars => { module => $mods->[0] },
        },
        post => {
            vars => { module => $mods->[0] },
        },
    },
    # NOTE: /v1/favorite
    "/v1/favorite" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/favorite/agg_by_distributions
    "/v1/favorite/agg_by_distributions" => {
        get => {
            query => "distribution=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
        },
        post => {
            payload => sub{ $mock->json->utf8->encode({ distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} }); },
        },
    },
    # NOTE: /v1/favorite/by_user/{user}
    "/v1/favorite/by_user/{user}" => {
        get => {
            vars => { user => $data->{users}->{ $users->[0] }->{user} },
        },
        post => {
            vars => { user => $data->{users}->{ $users->[0] }->{user} },
        },
    },
    # NOTE: /v1/favorite/leaderboard
    "/v1/favorite/leaderboard" =>
    {
        get => {},
        post => {},
    },
    # NOTE: /v1/favorite/recent
    "/v1/favorite/recent" =>
    {
        get => {},
        post => {},
    },
    # NOTE: /v1/favorite/users_by_distribution/{distribution}
    "/v1/favorite/users_by_distribution/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/favorite/{user}/{distribution}
    "/v1/favorite/{user}/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
                user => $data->{users}->{ $users->[0] }->{user},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
                user => $data->{users}->{ $users->[0] }->{user},
            },
        },
    },
    # NOTE: /v1/favorite/_search
    "/v1/favorite/_search" => {
        get => { query => "q=" . $users->[0] },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { author => $users->[0] },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/favorite/_search/scroll
    "/v1/favorite/_search/scroll" => {
        'delete' => {},
        get => { query => "q=" . $users->[0] . "&scroll=1m&scroll_id=something" },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { author => $users->[0] },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/file
    "/v1/file" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/file/dir/{path}
    "/v1/file/dir/{path}" => {
        get => {
            vars => { path => "lib/" . join( '/', split( /::/, $mods->[0] ) ) . ".pm" },
        },
        post => {
            vars => { path => "lib/" . join( '/', split( /::/, $mods->[0] ) ) . ".pm" },
        },
    },
    # NOTE: /v1/file/{author}/{release}/{path}
    "/v1/file/{author}/{release}/{path}" => {
        get => {
            vars => {
                author => $users->[0],
                path => "lib/" . join( '/', split( /::/, $mods->[0] ) ) . ".pm",
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                path => "lib/" . join( '/', split( /::/, $mods->[0] ) ) . ".pm",
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/file/_search
    "/v1/file/_search" => {
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/file/_search/scroll
    "/v1/file/_search/scroll" => {
        'delete' => {},
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} . "&scroll=1m&scroll_id=something" },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/login/index
    "/v1/login/index" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/mirror
    "/v1/mirror" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/mirror/search
    "/v1/mirror/search" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/module
    "/v1/module" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/module/{module}
    "/v1/module/{module}" => {
        get => {
            vars => { module => $mods->[0] },
        },
        post => {
            vars => { module => $mods->[0] },
        },
    },
    # NOTE: /v1/module/_search
    "/v1/module/_search" => {
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{name} },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { name => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{name} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/module/_search/scroll
    "/v1/module/_search/scroll" => {
        'delete' => {},
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{name} . "&scroll=1m&scroll_id=something" },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { name => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{name} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/package
    "/v1/package" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/package/modules/{distribution}
    "/v1/package/modules/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/package/{module}
    "/v1/package/{module}" => {
        get => {
            vars => { module => $mods->[0] },
        },
        post => {
            vars => { module => $mods->[0] },
        },
    },
    # NOTE: /v1/permission
    "/v1/permission" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/permission/by_author/{author}
    "/v1/permission/by_author/{author}" => {
        get => {
            vars => { author => $users->[0] },
        },
        post => {
            vars => { author => $users->[0] },
        },
    },
    # NOTE: /v1/permission/by_module
    "/v1/permission/by_module" => {
        get => { query => "module=" . $mods->[0] },
        post => {
            payload => sub{ $mock->json->utf8->encode({ module => $mods->[0] }); },
        },
    },
    # NOTE: /v1/permission/by_module/{module}
    "/v1/permission/by_module/{module}" => {
        get => {
            vars => { module => $mods->[0] },
        },
        post => {
            vars => { module => $mods->[0] },
        },
    },
    # NOTE: /v1/permission/{module}
    "/v1/permission/{module}" => {
        get => {
            vars => { module => $mods->[0] },
        },
        post => {
            vars => { module => $mods->[0] },
        },
    },
    # NOTE: /v1/pod/{author}/{release}/{path}
    "/v1/pod/{author}/{release}/{path}" => {
        get => {
            vars => {
                author => $users->[0],
                path => "lib/" . join( '/', split( /::/, $mods->[0] ) ) . ".pm",
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                path => "lib/" . join( '/', split( /::/, $mods->[0] ) ) . ".pm",
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/pod/{module}
    "/v1/pod/{module}" => {
        get => {
            vars => { module => $mods->[0] },
        },
        post => {
            vars => { module => $mods->[0] },
        },
    },
    # NOTE: /v1/pod_render
    "/v1/pod_render" => {
        get => {
            query => "pod=" . HTTP::Promise::Request->url_encode("=encoding utf-8\n\n=head1 Hello World\n\nSomething here\n\n=oops\n\n=cut\n"),
        },
        post => {
            payload => sub{ $mock->json->utf8->encode({ pod => "=encoding utf-8\n\n=head1 Hello World\n\nSomething here\n\n=oops\n\n=cut\n" }); },
        },
    },
    # NOTE: /v1/rating
    "/v1/rating" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/rating/by_distributions
    "/v1/rating/by_distributions" => {
        get => {
            query => "distribution=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
        },
        post => {
            payload => sub{ $mock->json->utf8->encode({ distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} }); },
        },
    },
    # NOTE: /v1/rating/_search
    "/v1/rating/_search" => {
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/rating/_search/scroll
    "/v1/rating/_search/scroll" => {
        'delete' => {},
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} . "&scroll=1m&scroll_id=something" },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/release
    "/v1/release" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/release/all_by_author/{author}
    "/v1/release/all_by_author/{author}" => {
        get => {
            vars => { author => $users->[0] },
        },
        post => {
            vars => { author => $users->[0] },
        },
    },
    # NOTE: /v1/release/by_author/{author}
    "/v1/release/by_author/{author}" => {
        get => {
            vars => { author => $users->[0] },
        },
        post => {
            vars => { author => $users->[0] },
        },
    },
    # NOTE: /v1/release/contributors/{author}/{release}
    "/v1/release/contributors/{author}/{release}" => {
        get => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/release/files_by_category/{author}/{release}
    "/v1/release/files_by_category/{author}/{release}" => {
        get => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/release/interesting_files/{author}/{release}
    "/v1/release/interesting_files/{author}/{release}" => {
        get => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/release/latest_by_author/{author}
    "/v1/release/latest_by_author/{author}" => {
        get => {
            vars => { author => $users->[0] },
        },
        post => {
            vars => { author => $users->[0] },
        },
    },
    # NOTE: /v1/release/latest_by_distribution/{distribution}
    "/v1/release/latest_by_distribution/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/release/modules/{author}/{release}
    "/v1/release/modules/{author}/{release}" => {
        get => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/release/recent
    "/v1/release/recent" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/release/top_uploaders
    "/v1/release/top_uploaders" => {
        get => {},
        post => {},
    },
    # NOTE: /v1/release/versions/{distribution}
    "/v1/release/versions/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/release/{author}/{release}
    "/v1/release/{author}/{release}" => {
        get => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/release/{distribution}
    "/v1/release/{distribution}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
            },
        },
    },
    # NOTE: /v1/release/_search
    "/v1/release/_search" => {
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release} },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/release/_search/scroll
    "/v1/release/_search/scroll" => {
        'delete' => {},
        get => { query => "q=" . $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release} . "&scroll=1m&scroll_id=something" },
        post => {
            payload => sub
            {
                $mock->json->utf8->encode({
                    query => { match_all => {} },
                    filter =>
                    {
                        and => [
                            {
                                term => { release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release} },
                            }
                        ],
                    },
                });
            },
        },
    },
    # NOTE: /v1/reverse_dependencies/dist/{distribution}
    "/v1/reverse_dependencies/dist/{distribution}" => {
        get => {
            vars => { distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
        },
        post => {
            vars => { distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} },
        },
    },
    # NOTE: /v1/reverse_dependencies/module/{module}
    "/v1/reverse_dependencies/module/{module}" => {
        get => {
            vars => { module => $mods->[0] },
        },
        post => {
            vars => { module => $mods->[0] },
        },
    },
    # NOTE: /v1/search
    "/v1/search" => {
        get => { query => "q=" . $mods->[0] },
    },
    # NOTE: /v1/search/autocomplete
    "/v1/search/autocomplete" => {
        get => {
            query => "q=" . [split( /-/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} )]->[0],
        },
    },
    # NOTE: /v1/search/autocomplete/suggest
    "/v1/search/autocomplete/suggest" => {
        get => {
            query => "q=" . [split( /-/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} )]->[0],
        },
    },
    # NOTE: /v1/search/first
    "/v1/search/first" => {
        get => {
            query => "q=" . [split( /-/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} )]->[0],
        },
    },
    # NOTE: /v1/search/history/documentation/{module}/{path}
    "/v1/search/history/documentation/{module}/{path}" => {
        get => {
            vars => {
                module => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{name},
                path => join( '/', ( 'lib', split( /::/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{package} ) ) ) . '.pm',
            },
        },
        post => {
            vars => {
                module => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{name},
                path => join( '/', ( 'lib', split( /::/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{package} ) ) ) . '.pm',
            },
        },
    },
    # NOTE: /v1/search/history/file/{distribution}/{path}
    "/v1/search/history/file/{distribution}/{path}" => {
        get => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
                path => join( '/', ( 'lib', split( /::/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{package} ) ) ) . '.pm',
            },
        },
        post => {
            vars => {
                distribution => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution},
                path => join( '/', ( 'lib', split( /::/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{package} ) ) ) . '.pm',
            },
        },
    },
    # NOTE: /v1/search/history/module/{module}/{path}
    "/v1/search/history/module/{module}/{path}" => {
        get => {
            vars => {
                module => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{name},
                path => join( '/', ( 'lib', split( /::/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{package} ) ) ) . '.pm',
            },
        },
        post => {
            vars => {
                module => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{name},
                path => join( '/', ( 'lib', split( /::/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{package} ) ) ) . '.pm',
            },
        },
    },
    # NOTE: /v1/search/web
    "/v1/search/web" => {
        get => {
            query => "q=" . [split( /-/, $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{distribution} )]->[0],
        },
    },
    # NOTE: /v1/source/{author}/{release}/{path}
    "/v1/source/{author}/{release}/{path}" => {
        get => {
            vars => {
                author => $users->[0],
                path => "lib/" . join( '/', split( /::/, $mods->[0] ) ) . ".pm",
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
        post => {
            vars => {
                author => $users->[0],
                path => "lib/" . join( '/', split( /::/, $mods->[0] ) ) . ".pm",
                release => $data->{users}->{ $users->[0] }->{modules}->{ $mods->[0] }->{release},
            },
        },
    },
    # NOTE: /v1/source/{module}
    "/v1/source/{module}" => {
        get => {
            vars => { module => $mods->[0] },
        },
        post => {
            vars => { module => $mods->[0] },
        },
    },
};

# NOTE: test -> operation IDs
# Check if all operations documented are represented
subtest 'operation IDs' => sub
{
    my $specs = $mock->specs;
    foreach my $path ( sort( keys( %{$specs->{paths}} ) ) )
    {
        subtest $path => sub
        {
            # _mapping path are treated separately
            if( [split( '/', $path )]->[-1] eq '_mapping' && 
                !exists( $tests->{ $path } ) )
            {
                pass( "test is skipped for GET $path" );
                # next;
                return;
            }
            foreach my $meth ( sort( keys( %{$specs->{paths}->{ $path }} ) ) )
            {
                my $this = $specs->{paths}->{ $path }->{ $meth };
                if( (
                        exists( $data->{ $this->{operationId} } ) ||
                        exists( $data->{alias}->{ $this->{operationId} } )
                    ) && ( !exists( $tests->{ $path } ) || !exists( $tests->{ $path }->{ $meth } ) ) )
                {
                    pass( "test is skipped for \U${meth}\E $path" );
                    next;
                }
                diag( "Test for \U${meth}\E $path does not exists and operationId '", ( $this->{operationId} // 'undef' ), "' is not present in generated data." ) if( !exists( $tests->{ $path }->{ $meth } ) );
                ok( exists( $tests->{ $path }->{ $meth } ), "test exists for \U${meth}\E $path" );
                $tests->{ $path }->{ $meth } = {} if( !exists( $tests->{ $path }->{ $meth } ) );
                if( exists( $this->{operationId} ) )
                {
                    $tests->{ $path }->{ $meth }->{id} = $this->{operationId};
                    pass( "operation ID exists for \U${meth}\E ${path}" );
                    my $opid = $this->{operationId};
                    ok( ( $mock->can( "_${opid}" ) || exists( $data->{ $opid } ) || exists( $data->{alias}->{ $opid } ) ), "${opid} -> can \$mock->_${opid}" );
                }
                else
                {
                    fail( "operation ID does not exist for \U${meth}\E ${path}" );
                    fail( "missing operation ID to check equivalent perl method" );
                }
            }
        };
    }
};

# NOTE: test -> tests
foreach my $path ( sort( keys( %$tests ) ) )
{
    subtest $path => sub
    {
        foreach my $meth ( sort( keys( %{$tests->{ $path }} ) ) )
        {
            my $this = $tests->{ $path }->{ $meth };
            my $id = $this->{id};
            if( !defined( $id ) )
            {
                fail( "No operation ID found for \U${meth}\E $path" );
                next;
            }
        
            if( my $coderef = $mock->can( "_${id}" ) )
            {
                my $payload;
                if( exists( $this->{payload} ) )
                {
                    if( ref( $this->{payload} ) eq 'CODE' )
                    {
                        $payload = $this->{payload}->();
                    }
                    else
                    {
                        $payload = $this->{payload};
                    }
                    $this->{type} = 'application/json';
                }
                my $url = "http://localhost:1234${path}";
                if( exists( $this->{vars} ) && ref( $this->{vars} ) eq 'HASH' )
                {
                    # $url =~ s/\{([^\}]+)\}/$this->{vars}->{ $1 }/g;
                    $url =~ s{
                        \{([^\}]+)\}
                    }
                    {
                        if( exists( $this->{vars}->{ $1 } ) )
                        {
                            diag( "Replacing '$1' with '", $this->{vars}->{ $1 }, "'" ) if( $DEBUG > 1 );
                            $this->{vars}->{ $1 };
                        }
                        else
                        {
                            warn( "Missing variable '$1' for path ${path} and method ${meth}" );
                            "\{$1\}";
                        }
                    }gexs;
                }
                $req = HTTP::Promise::Request->new( uc( $meth ) => $url . ( exists( $this->{query} ) ? '?' . $this->{query} : '' ), [
                    Accept => ( exists( $this->{accept} ) ? $this->{accept} : 'application/json' ),
                    ( defined( $payload ) ? ( Content => $payload, Content_Length => length( $payload ) ) : () ),
                    (
                        exists( $this->{type} )
                            ? ( Content_Type => $this->{type} )
                            : $meth eq 'post'
                                ? ( Content_Type => 'application/json' )
                                : ()
                    ),
                ] );
                diag( $req->as_string ) if( $DEBUG );
                $resp = $coderef->( $mock, request => $req, ( exists( $this->{vars} ) ? ( vars => $this->{vars} ) : () ) );
                isa_ok( $resp => 'HTTP::Promise::Response', "\U${meth}\E ${path}" );
                diag( "\U${meth}\E ", $req->uri->path_query, " -> ", $resp->status_line ) if( defined( $resp ) && !$resp->is_success );
                if( defined( $resp ) && 
                    !$resp->is_success && 
                    $resp->code == 501 )
                {
                    pass( "Skipping \U${meth}\E ${path} with code 501 (to be completed)" );
                }
                else
                {
                    ok( $resp->is_success, "\U${meth}\E ${path} -> " . $resp->status_line ) if( defined( $resp ) );
                    diag( $resp->as_string ) if( $DEBUG && defined( $resp ) && !$resp->is_success );
                }
            }
            else
            {
                ok( ( exists( $data->{ $id } ) || exists( $data->{alias}->{ $id } ) ), "\U${meth}\E ${path} -> 200 OK" );
            }
        }
    };
}

done_testing();

__END__

