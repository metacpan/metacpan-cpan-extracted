# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Numeric-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
my(%ops, $vars);
BEGIN { %ops  = qw( lt < le <= gt > ge >= eq == ne != ); $vars = 4 }
use Test::More tests => 4 + (keys %ops) * $vars * $vars * 2 ;

# Check aliasing: alias X to L
BEGIN { use_ok('Numeric::LL_Array', qw( :X=L packId_i packId_X access_i access_X LX2i2_le ),
          map +("iX2i2_$_", "ii2i2_$_", "XL2X2_$_", "XX2X2_$_", "Xi2i2_$_"), keys %ops) };

#                                        iL2i2_lt ii2i2_lt Li2i2_lt
#                                        iL2i2_gt ii2i2_gt Li2i2_gt
#                                        iL2i2_le ii2i2_le Li2i2_le
#                                        iL2i2_ge ii2i2_ge Li2i2_ge

my $neg_one = pack packId_i, -1;
my $one     = pack packId_i, 1;
my $three   = pack packId_i, 3;
my $unsigned_two = pack packId_X, 2;
my $res = pack packId_i, 0;
my $resL = pack packId_X, 0;
ok(1, "data for comparison created");

my @vars = ( [$neg_one,      'i', -1],
	     [$one,          'i',  1],
	     [$unsigned_two, 'X',  2],
	     [$three,        'i',  3],
	   );
@vars == $vars or die "Not predeclared number of variables";

LX2i2_le($unsigned_two, $unsigned_two, $res, 0, 0, 0, 0, "", "", "");
ok(1, "finished comparison 2 <= 2 with signed int result");
is_deeply(access_i($res), 1, "... 2 <= 2 with signed int result correct");

for my $op (keys %ops) {
  for my $first (@vars) {
    for my $second (@vars) {	# output must be one of inputs
      my ($out, $acc, $r) = "$first->[1]$second->[1]" eq 'XX'
	? ('X', \&access_X, $res) : ('i', \&access_i, $resL);
      my $subr = "$first->[1]$second->[1]2${out}2_$op";
      $subr = do {
        no strict 'refs';
        \&$subr
      };
      $subr->($first->[0], $second->[0], $r, 0, 0, 0, 0, "", "", "");
      ok(1, "finished comparison $first->[2] $ops{$op} $second->[2]");
      my $expect;
      eval " \$expect = $first->[2] $ops{$op} $second->[2]; 1" or die;
      is_deeply($acc->($r), $expect || 0, "... $first->[2] $ops{$op} $second->[2] correct");
    }
  }
}
