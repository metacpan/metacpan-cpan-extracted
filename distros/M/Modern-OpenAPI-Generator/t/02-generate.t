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
    name        => 'Gen::Mini::API',
    force       => 1,
    signatures  => ['hmac'],
)->run;

ok( -e File::Spec->catfile( $td, 'share', 'openapi.yaml' ), 'spec copied' );
ok( -e File::Spec->catfile( $td, 'lib', 'Gen', 'Mini', 'API', 'Client', 'Core.pm' ), 'client core' );
ok( -e File::Spec->catfile( $td, 'lib', 'Gen', 'Mini', 'API', 'Server.pm' ), 'server' );
ok( -e File::Spec->catfile( $td, 'README.md' ), 'generated README.md' );
ok( -e File::Spec->catfile( $td, 'docs', 'DefaultApi.md' ), 'generated docs/DefaultApi.md' );
ok( -e File::Spec->catfile( $td, 'lib', 'Gen', 'Mini', 'API', 'Model', 'PingResponse.pm' ),
    'generated Model:: from components/schemas' );
ok( -e File::Spec->catfile( $td, 't', '00-load-generated.t' ), 'generated t/ for output tree' );

{
    my $cp = File::Spec->catfile( $td, 'lib', 'Gen', 'Mini', 'API', 'Server', 'Controller.pm' );
    open my $fh, '<', $cp or die $!;
    my $ctl = do { local $/; <$fh> };
    close $fh;
    like( $ctl, qr/openapi->valid_input/, 'server controller validates request' );
}
{
    my $cp = File::Spec->catfile( $td, 'lib', 'Gen', 'Mini', 'API', 'Client', 'Core.pm' );
    open my $fh, '<', $cp or die $!;
    my $core = do { local $/; <$fh> };
    close $fh;
    like( $core, qr/validate_response/, 'client validates response before inflate' );
}

done_testing;
