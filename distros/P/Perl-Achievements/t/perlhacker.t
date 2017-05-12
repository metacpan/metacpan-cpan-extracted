use strict;
use warnings;

use Test::More tests => 2;

use Perl::Achievements;

my $pa = Perl::Achievements->new(
    interactive => 0,
    dry_run => 1,
);

my $ach = Perl::Achievements::Achievement::PerlHacker->new(
    app => $pa,
);

is $ach->level => 0, 'level 0 by default';

my $code = "print 'yet another perl hacker';\n"x11;

$pa->set_ppi( PPI::Document->new( \$code ) );

$ach->scan;

is $ach->level => 1, 'leveled up!';


