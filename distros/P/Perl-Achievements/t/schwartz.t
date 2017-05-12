use strict;
use warnings;

use Test::More tests => 6;

use Perl::Achievements;

my $pa = Perl::Achievements->new(
    interactive => 0,
    dry_run => 1,
);

my $ach = Perl::Achievements::Achievement::SchwartzianTransform->new(
    app => $pa,
);

is $ach->level => 0, 'level 0 by default';

my $code = <<'END_CODE';
    my %h = ( 'yanick' => 1, 'drool' => 2 );
    my @x = map { s/^.*?_//; $_; }  
            sort { $a <=> $b } 
            map { $h{$_}.'_'.$_ } 
            keys %h;
END_CODE

$pa->set_ppi( PPI::Document->new( \$code ) );
$ach->scan;

is $ach->level => 1, 'leveled up!';

$ach->scan for 1..10;

is $ach->level => 4;
is $ach->transformations => 11;

$ach->scan for 1..5;

is $ach->level => 5;
is $ach->transformations => 16;




