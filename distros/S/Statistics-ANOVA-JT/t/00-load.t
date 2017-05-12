use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok( 'Statistics::ANOVA::JT' ) || print "Bail out!\n";
}

my $aov = Statistics::ANOVA::JT->new();
isa_ok($aov, 'Statistics::Data');

diag( "Testing Statistics::ANOVA::JT $Statistics::ANOVA::JT::VERSION, Perl $], $^X" );
