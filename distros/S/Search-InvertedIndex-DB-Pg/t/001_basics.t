use strict;
use Test::More tests => 2;

use_ok( "Search::InvertedIndex::DB::Pg" );

SKIP: {
    skip "Test database not configured", 1 unless -e "test.conf";

    require Config::Tiny;
    my $conf_ref = Config::Tiny->read( "test.conf" );
    my %conf = %{ $conf_ref->{_} };

    my $db = Search::InvertedIndex::DB::Pg->new(
        -db_name    => $conf{dbname},
        -hostname   => $conf{dbhost},
        -port       => $conf{dbport},
        -username   => $conf{dbuser},
        -password   => $conf{dbpass},
        -table_name => "siindex",
        -lock_mode  => "EX",
    );

    isa_ok( $db, "Search::InvertedIndex::DB::Pg" );

} # end of SKIP

