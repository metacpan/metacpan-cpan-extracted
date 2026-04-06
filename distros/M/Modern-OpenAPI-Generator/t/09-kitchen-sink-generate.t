use v5.26;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Modern::OpenAPI::Generator;

# Integration: diverse schema properties (see t/data/schema_kitchen_sink.yaml).
my $td   = tempdir( CLEANUP => 1 );
my $spec = File::Spec->catfile( 't', 'data', 'schema_kitchen_sink.yaml' );

Modern::OpenAPI::Generator->new(
    spec_path  => $spec,
    output_dir => $td,
    name       => 'Gen::Kitchen::API',
    force      => 1,
)->run;

my $base = File::Spec->catfile( $td, 'lib', 'Gen', 'Kitchen', 'API' );
ok( -e File::Spec->catfile( $base, 'Model', 'OuterDto.pm' ), 'OuterDto model' );
ok( -e File::Spec->catfile( $base, 'Model', 'InnerDto.pm' ), 'InnerDto model' );

{
    my $p = File::Spec->catfile( $base, 'Model', 'OuterDto.pm' );
    open my $fh, '<', $p or die $!;
    my $txt = do { local $/; <$fh> };
    close $fh;
    like( $txt, qr/Enum\[/, 'enum column maps to Enum' ) or diag $txt;
}

done_testing;
