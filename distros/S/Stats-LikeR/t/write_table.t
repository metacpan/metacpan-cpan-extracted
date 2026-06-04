use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';
use Stats::LikeR;

my $flat_hash = {
 A => 1, B => 2
};

# ---------------------------------------------------------
# Test 1: Flat hash with row.names = 0
# The output should exactly match: A,B \n 1,2
# ---------------------------------------------------------
my ($fh1, $file1) = tempfile(SUFFIX => '.csv', UNLINK => 1);
write_table($flat_hash, $file1, sep => ',', 'row.names' => 0);

open my $in1, '<', $file1 or die "Could not open $file1: $!";
my @lines1 = <$in1>;
close $in1;
chomp @lines1;

like($lines1[0], qr/^(?:""|'')?A(?:""|'')?,(?:""|'')?B(?:""|'')?$/, "Flat hash (rownames=0) Headers are keys");
like($lines1[1], qr/^(?:""|'')?1(?:""|'')?,(?:""|'')?2(?:""|'')?$/, "Flat hash (rownames=0) Values are on row 1");

# ---------------------------------------------------------
# Test 2: Flat hash with row.names = 1 (Default behavior)
# Output gracefully prepends the implicit "1" row identifier:
# "",A,B
# "1",1,2
# ---------------------------------------------------------
my ($fh2, $file2) = tempfile(SUFFIX => '.csv', UNLINK => 1);
write_table($flat_hash, $file2, sep => ',');

open my $in2, '<', $file2 or die "Could not open temp file: $!";
my @lines2 = <$in2>;
close $in2;
chomp @lines2;

like($lines2[0], qr/^(?:""|'')?,(?:""|'')?A(?:""|'')?,(?:""|'')?B(?:""|'')?$/, "Flat hash (rownames=1) Header prepends blank");
like($lines2[1], qr/^(?:""|'')?1(?:""|'')?,(?:""|'')?1(?:""|'')?,(?:""|'')?2(?:""|'')?$/, "Flat hash (rownames=1) Row prepends '1'");
done_testing();
