# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..33\n"; }
END {print "not ok 1\n" unless $loaded;}
use Pogo;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "open...\n";
$pogo = new Pogo("test.cfg");
  test(2, ref($pogo) eq 'Pogo');

print "scalar...\n";
$scalar = new Pogo::Scalar;
  test(3, ref($scalar) eq 'Pogo::Scalar');
$scalar->set("test");
  test(4, $scalar->get eq "test");

print "array...\n";
$array = new Pogo::Array;
  test(5, ref($array) eq 'Pogo::Array');
$array->set(0, $scalar);
  test(6, $array->get(0)->get eq "test");
$array->set(1, "test1");
  test(7, $array->get(1) eq "test1");
$array->push("test2");
  test(8, $array->pop eq "test2");
  test(9, $array->remove(1) eq "test1");

print "hash...\n";
$hash = new Pogo::Hash(16);
  test(10, ref($hash) eq 'Pogo::Hash');
$hash->set("test", $scalar);
  test(11, $hash->get("test")->get eq "test");
$hash->set("test2", "test");
  test(12, $hash->get("test2") eq "test");
@keys = ();
push @keys, $hash->first_key;
push @keys, $hash->next_key($keys[0]);
  test(13, join(',',sort @keys) eq "test,test2");

print "htree...\n";
$htree = new Pogo::Htree(16);
  test(14, ref($htree) eq 'Pogo::Htree');
$htree->set("test", $scalar);
  test(15, $htree->get("test")->get eq "test");
$htree->set("test2", "test");
  test(16, $htree->get("test2") eq "test");
@keys = ();
push @keys, $htree->first_key;
push @keys, $htree->next_key($keys[0]);
  test(17, join(',',sort @keys) eq "test,test2");

print "btree...\n";
$btree = new Pogo::Btree;
  test(18, ref($btree) eq 'Pogo::Btree');
$btree->set("test", $scalar);
  test(19, $btree->get("test")->get eq "test");
$btree->set("test2", "test");
  test(20, $btree->get("test2") eq "test");
@keys = ();
push @keys, $btree->first_key;
push @keys, $btree->next_key($keys[0]);
  test(21, join(',',sort @keys) eq "test,test2");

print "ntree...\n";
$ntree = new Pogo::Ntree;
  test(22, ref($ntree) eq 'Pogo::Ntree');
$ntree->set(10, $scalar);
  test(23, $ntree->get(10)->get eq "test");
$ntree->set(2, "test");
  test(24, $ntree->get(2) eq "test");
@keys = ();
push @keys, $ntree->first_key;
push @keys, $ntree->next_key($keys[0]);
  test(25, join(',', @keys) eq "2,10");

print "tie...\n";

$scalarref = new_tie Pogo::Scalar;
$$scalarref = "test";
  test(26, $$scalarref eq "test");
$arrayref = new_tie Pogo::Array 1;
$arrayref->[1] = "test";
  test(27, $arrayref->[1] eq "test");
$hashref = new_tie Pogo::Hash 16;
$hashref->{test} = "test";
  test(28, $hashref->{test} eq "test");
$htreeref = new_tie Pogo::Htree 16;
$htreeref->{test} = "test";
  test(29, $htreeref->{test} eq "test");
$btreeref = new_tie Pogo::Btree;
$btreeref->{test} = "test";
  test(30, $btreeref->{test} eq "test");
$btreeref->{hash} = $hashref;
  test(31, $btreeref->{hash}->{test} eq "test");
$ntreeref = new_tie Pogo::Ntree;
$ntreeref->{5} = "test";
  test(32, $ntreeref->{5} eq "test");
$ntreeref->{1000} = $hashref;
  test(33, $ntreeref->{1000}->{test} eq "test");

sub test {
	my($chunk, $result) = @_;
	print $result ? "ok $chunk\n" : "not ok $chunk\n"; 
}
