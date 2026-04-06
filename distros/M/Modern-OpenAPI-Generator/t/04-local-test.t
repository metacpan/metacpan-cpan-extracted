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
    name        => 'Gen::Local::API',
    force       => 1,
    signatures  => [],
    local_test  => 1,
)->run;

my $stub = File::Spec->catfile( $td, 'lib', 'Gen', 'Local', 'API', 'StubData.pm' );
ok( -e $stub, 'StubData generated' );

my $ctl = File::Spec->catfile( $td, 'lib', 'Gen', 'Local', 'API', 'Server', 'Controller.pm' );
ok( -e $ctl, 'controller exists' );

my $txt = do { local ( @ARGV, $/ ) = ($ctl); <> };
like( $txt, qr/StubData->for_operation/, 'local-test uses StubData + models' );
like( $txt, qr/openapi->valid_input/, 'controller validates incoming request' );
unlike( $txt, qr/Not implemented/, 'local-test controller skips 501 stub message' );
like( $txt, qr/render\(\s*status\s*=>\s*\$st/, 'controller passes status from StubData' );

done_testing;
