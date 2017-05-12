use strict;
use warnings;
use utf8;
use Test::More;
use PLON;

open *FH, '>', \my $out;
my $plon = PLON->new->encode(\*FH);
note $plon;
my $newfh = PLON->new->decode($plon);
print {$newfh} "UWAA";
is $out, 'UWAA';

done_testing;

