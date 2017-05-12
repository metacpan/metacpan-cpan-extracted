use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;

my $tmp = File::Temp->new();
print {$tmp} "\xEF\xBB\xBF5963";
is(`./pvip $tmp`, "(statements (int 5963))\n");

done_testing;

