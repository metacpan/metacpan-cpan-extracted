use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok( 'Statistics::Data::Rank' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Data::Rank $Statistics::Data::Rank::VERSION, Perl $], $^X" );

my $rankd = Statistics::Data::Rank->new();
isa_ok($rankd, 'Statistics::Data');

1;