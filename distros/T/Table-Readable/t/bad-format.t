use FindBin '$Bin';
use lib "$Bin";
use TRTest;
my @moo;
@moo=trfile ("$Bin/bad-format.txt");
ok (! $moo[0]{ja}, "Did not get ja field from badly-formatted file");
done_testing ();
