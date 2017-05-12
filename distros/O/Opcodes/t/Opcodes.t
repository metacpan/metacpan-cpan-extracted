#!perl -w
BEGIN { $| = 1 } # Autoflush
use Test::More;

use Opcodes;
use Opcode qw(opset_to_ops full_opset);
use strict;

plan( tests => 18 );

# --- ensure all matching Opcode

my @full_l1  = opset_to_ops(full_opset);
ok @full_l1 == opcodes(), "opcodes == opset_to_ops(full_opset)";
my @full_l2 = map { $_->[1] } opcodes(); # names only
ok "@full_l1" eq "@full_l2", "opnames match, correct order";

# --- opdesc and other opcodes properties

my $gv = opname2code('gv');
ok $gv, "opname2code gv";
ok opdesc($gv) eq "glob value", "opdesc";
@full_l1 = opcodes();
ok @full_l1, "opcodes";
my $op0 = $full_l1[0];
ok @$op0 == 5, "scalar opcodes[0] = 5";

ok opname(0) eq 'null', "opname";
SKIP: {
  # fails for <5.8.9
  if (opaliases(0)) {
    my $ppaddr = Opcodes::ppaddr(0);
    ok ($ppaddr eq Opcodes::ppaddr(2), "ppaddr");
  } else {
    skip "no opaliases(0) in $]", 1;
  }
}
my $check = Opcodes::check(0);
ok ($check eq Opcodes::check(1), "check");

ok opargs(0) == 0, "opargs";
my @al = opaliases(0); #scalar regcmaybe lineseq scope
SKIP: {
  if (@al) {
    my $result = ((@al == 4) and ($al[0] == 2));
    ok $result, "opaliases";
  } else {
    # fails for <5.8.9
    skip "no opaliases(0) in $]", 1;
  }
}

# find bless at 23
my $bless;
for (0..@full_l1) { if (opname($_) eq 'bless') { $bless = $_; last } }
ok $bless == opname2code('bless'), "opname2code";
ok ((opargs($bless) & OA_LISTOP) == OA_LISTOP, "bless: OA_LISTOP");
ok Opcodes::opclass($bless) == 4, "bless: listop 4 @";
ok ((opflags($bless) & 511) == 4, "bless: flags 4(s) in ".opflags($bless));
ok Opcodes::argnum($bless) == 145, "bless: S S? 145";

# check if return maybranch
ok Opcodes::maybranch(opname2code('return')), "return: maybranch";

# --- finally, check some opname assertions

foreach(@full_l2) { die "bad opname: $_" if /\W/ or /^\d/ }

pass "no bad opname assertion";
