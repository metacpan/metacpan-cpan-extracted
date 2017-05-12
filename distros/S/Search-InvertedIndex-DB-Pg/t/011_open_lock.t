use strict;
use Test::More tests => 10;

use Search::InvertedIndex;
use Search::InvertedIndex::DB::Pg;

SKIP: {
    skip "Test database not configured", 10 unless -e "test.conf";

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

    my $map = Search::InvertedIndex->new( -database => $db );
    isa_ok( $map, "Search::InvertedIndex" );

    ok( $map->status( "-open" ), "map successfully opened" );

    is( $map->status( "-lock_mode" ), "EX",
        "...and lock mode is correctly set" );

    # Now faff with the lock mode.
    foreach my $mode ( qw( SH UN EX ) ) {
        eval {
            $map->lock( -lock_mode => $mode );
        };
        is( $@, "", "setting lock mode to $mode doesn't die" );

        is( $map->status( "-lock_mode" ), $mode,
            "...and it was set correctly" );
    }

    eval { $map->close; };
    is( $@, "", "map successfully closed" );

} # end of SKIP

