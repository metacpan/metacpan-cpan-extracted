# -*- perl -*-

use strict;
use Config;

BEGIN { $Set::IntSpan::integer = 1 }
use News::Newsrc 1.10;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, " @_\n" }

print "1..1\n";

my $rc = new News::Newsrc;
$rc->mark_range('a', 1_000_000_000_000, 1_000_000_000_100);

for my $i (0..100)
{	
    mark $rc 'a', 2e12+$i;
}

if ($Config{ivsize}==4)
{
    $rc->get_articles('a') eq '1000000000100' or Not; OK 'no integer';
}
else
{
    OK '# SKIP not a 32-bit platform';
}
