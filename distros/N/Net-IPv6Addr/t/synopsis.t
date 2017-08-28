use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
my $synopsis;
open my $in, "<", "$Bin/../examples/synopsis.pl" or die $!;
while (<$in>) {
$synopsis .= $_;
}
close $in or die $!;
eval $synopsis;
ok (! $@);
if ($@) {
    diag ($@);
}
done_testing ();
