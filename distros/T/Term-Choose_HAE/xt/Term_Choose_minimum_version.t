use 5.010000;
use strict;
use warnings;
use Time::Piece;
use Test::More;
use Term::Choose;


my $term_choose_minimum_version = -1;

open my $fh, '<', 'Makefile.PL' or die $!;
while ( my $line = <$fh> ) {
    if ( $line =~ /^\s*'Term::Choose'\s*=>\s*'([0-9\.]+)'/ ) {
        $term_choose_minimum_version = $1;
    }
}
close $fh;

my $term_choose_version = $Term::Choose::VERSION // - 2;


is( $term_choose_minimum_version, $term_choose_version, 'Term::Choose minimum version OK' );

done_testing;
