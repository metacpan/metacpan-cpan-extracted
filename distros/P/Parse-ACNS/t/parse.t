use strict;
use warnings;

use Test::More tests => 17;
use File::Spec;
use YAML::Any qw(LoadFile);

use_ok('Parse::ACNS');

foreach my $spec (qw(0.6 0.7 1.0 1.1 1.2)) {
    foreach my $file ( glob File::Spec->catfile(qw(t data), $spec, '*.xml') ) {
        foreach my $version ( $spec, 'compat' ) {
            note "parsing $file in $version mode";
            my $p = Parse::ACNS->new( version => $version );
            my $got = $p->parse( XML::LibXML->new->parse_file( $file ) );
            ok($got, "parsed '$file' in $version version mode");
            if ( $ENV{'TEST_VERBOSE'} ) {
                require Data::Dumper;
                #    diag( Data::Dumper::Dumper( $got ) );
            }
            my $expected = LoadFile( substr($file, 0, -3) .'yaml' );
            if ( $version eq 'compat' ) {
                delete $_->{'schemaVersion'} for $got, $expected;
            }
            is_deeply($got, $expected, 'data matches expected');
        }
    }
}
