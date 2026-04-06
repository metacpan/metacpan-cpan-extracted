use v5.26;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Modern::OpenAPI::Generator;

my $td = tempdir( CLEANUP => 1 );
my $spec = File::Spec->catfile( 't', 'data', 'minimal.yaml' );

Modern::OpenAPI::Generator->new(
    spec_path   => $spec,
    output_dir  => $td,
    name        => 'Gen::NoClient::API',
    force       => 1,
    client      => 0,
    server      => 1,
    ui          => 0,
    local_test  => 1,
    signatures  => [],
)->run;

ok(
    -e File::Spec->catfile( $td, 'lib', 'Gen', 'NoClient', 'API', 'Model',
        'PingResponse.pm' ),
    'PingResponse model emitted without --client when --local-test + server'
);
ok( !-e File::Spec->catfile( $td, 'lib', 'Gen', 'NoClient', 'API', 'Client', 'Core.pm' ),
    'Client::Core not emitted without --client' );

done_testing;
