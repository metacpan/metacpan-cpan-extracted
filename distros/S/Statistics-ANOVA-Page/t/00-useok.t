use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok( 'Statistics::ANOVA::Page' ) || print "Bail out!\n";
}

my $aov = Statistics::ANOVA::Page->new();
isa_ok($aov, 'Statistics::Data');

diag( "Testing Statistics::ANOVA::Page $Statistics::ANOVA::Page::VERSION, Perl $], $^X" );
1;