use strict;
use warnings;
use Test::More;
use File::Temp;

my $fh = File::Temp->new();
print {$fh} '"\0"';
is(system("./pvip $fh"), 0);

done_testing;
