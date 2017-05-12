use Test::More;
use strict;
use warnings;

BEGIN {
    use_ok('RDF::Helper');
    use_ok('RDF::Helper::Constants');
}

my $found_libs = 0;

test( base => 'RDF::Redland', class => 'RDF::Helper::RDFRedland' );
test( base => 'RDF::Trine', class => 'RDF::Helper::RDFTrine' );

ok( $found_libs > 0) or diag("You must have one of Perl's RDF libraries (RDF::Redland, RDF::Trine etc.) installed for this package to work!!!");

sub test {
    my %args = @_;
  SKIP: {
        eval "require $args{base}";
        skip "$args{base} not installed", 1 if $@;

        my $helper = RDF::Helper->new( BaseInterface => $args{base} );
        $found_libs++;
        isa_ok( $helper, 'RDF::Helper' );
        isa_ok($helper->backend, $args{class} );
    }
}

done_testing();
