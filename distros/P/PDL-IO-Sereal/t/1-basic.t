use strict;
use warnings;

use Test::More tests => 6;
use PDL;
use PDL::IO::Sereal ':all';

unlink "tmp.sereal";

my $pdl0 = zeroes(longlong, 10,10);
$pdl0->hdr->{key0} = 'zero';

my $pdl1 = long(random(12,34,56,78) * 1000000);
$pdl1->hdr->{key1} = "one";
$pdl1->hdr->{key2} = 2;
$pdl1->hdr->{key3} = $pdl0;
$pdl1->wsereal("tmp.sereal");
my $pdl2 = rsereal("tmp.sereal");

ok(all($pdl1 == $pdl2));
is($pdl1->info, $pdl2->info);
is($pdl2->hdr->{key1}, "one");
is($pdl2->hdr->{key2}, 2);
is($pdl2->hdr->{key3}->info, 'PDL: LongLong D [10,10]');
is($pdl2->hdr->{key3}->hdr->{key0}, 'zero');

unlink "tmp.sereal";