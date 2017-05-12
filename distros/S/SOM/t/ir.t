# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..24\n"; }
END {print "not ok 1\n" unless $loaded;}
use SOM ':types', ':class';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$repo = RepositoryNew;
print "ok 2\n";
ref $repo eq 'RepositoryPtr' or print "not ";
print "ok 3\n";

$ev = SOM::CreateLocalEnvironment();
print "not " unless $ev;
print "ok 4\n";

$list = $repo->contents_($ev, 'InterfaceDef', 1);
print "ok 5\n";

print "# scal ", length($list), "\n";

@list = $repo->contents($ev, 'InterfaceDef', 1);
print "ok 6\n";

print "# arr ", scalar(@list), "\n";

my $folder;
my $c = 0;
foreach my $item (@list) {
  my $class = $item->GetClassName;
  print "# class => '$class', name => '", $item->name($ev), "', id => '", $item->id($ev),
  	 "', defined_in => '",	$item->defined_in($ev), "'\n";
  $c++, $folder = $item if $item->name($ev) eq 'WPFolder';
}
print "ok 7\n";

$c == 1 or print "not ";
print "ok 8\n";

$folder or print "not ";
print "ok 9\n";

@list1 = $folder->contents($ev, 'all', 0);
print "ok 10\n";

my $open;
foreach my $item (@list1) {
  my $class = $item->GetClassName;
  print "## class => '$class', name => '", $item->name($ev), "', id => '", $item->id($ev),
  	 "', defined_in => '",	$item->defined_in($ev), "'\n";
  $open = $item if $item->name($ev) eq 'wpOpen';
  $setup = $item if $item->name($ev) eq 'wpSetup';
}
print "ok 11\n";

$open or print "not ";
print "ok 12\n";

@list2 = $open->contents($ev, 'all', 0);
print "ok 13\n";

foreach my $item (@list2) {
  my $class = $item->GetClassName;
  print "### class => '$class', name => '", $item->name($ev), "', id => '", $item->id($ev),
  	 "', defined_in => '",	$item->defined_in($ev), "'\n";
}
print "ok 14\n";

$setup or print "not ";
print "ok 15\n";

bless $open, 'OperationDefPtr';
$tc0 = $open->result($ev);
$pc0 = $tc0->param_count($ev);
$k0 = $tc0->kind($ev);
print "# wpOpen result's typecode kind=$k0, $pc0 params\n";

$k0 == 6 and $pc0 eq '0' or print "# k0=$k0, pc0 = $pc0\nnot ";
print "ok 16\n";

@list2 == 3 or print "not ";
print "ok 17\n";

for (0..$#list2) {
  bless $list2[$_], 'ParameterDefPtr';
  $tc[$_] = $list2[$_]->type($ev);
  $pc[$_] = $tc[$_]->param_count($ev);
  $name = $list2[$_]->name($ev);
  $k[$_] = $tc[$_]->kind($ev);
  print "# wpOpen ${name}'s typecode kind=$k[$_], $pc[$_] params\n";
  $k[$_] == 6 and $pc[$_] eq '0' or print "# k[$_]=$k[$_], pc[$_]=$pc[$_]\nnot ";
  $test = $_ + 18;
  print "ok $test\n";
}

bless $setup, 'OperationDefPtr';
$tc0 = $setup->result($ev);
$pc0 = $tc0->param_count($ev);
$k0 = $tc0->kind($ev);
print "# wpSetup result's typecode kind=$k0, $pc0 params\n";

# BOOL is typedef to int, which in IDL is mapped to long
$k0 == 4 or print "# k0=$k0, pc0 = $pc0\nnot ";
print "ok 21\n";

$pc0 eq '0' or print "# k0=$k0, pc0 = $pc0\nnot ";
print "ok 22\n";

@list3 = $setup->contents($ev, 'all', 0);
print "ok 23\n";

@list3 == 1 or print "not ";
print "ok 24\n";

exit 0;

# This does not work, since TypeCode_parameter returns junk *and* destroys
# its first argument.

for (0..$#list3) {
  bless $list3[$_], 'ParameterDefPtr';
  $tc[$_] = $list3[$_]->type($ev);
  $pc[$_] = $tc[$_]->param_count($ev);
  $name = $list3[$_]->name($ev);
  $k[$_] = $tc[$_]->kind($ev);
  my $k2 = $tc[$_]->parameter_type_kind($ev,0);
  print "##### 1st parameter kind=$k2 (in XS - first).\n";
  print "# wpSetup ${name}'s typecode kind=$k[$_], $pc[$_] params\n";
# One parameter for maxlen
  $k[$_] == 19 and $pc[$_] eq '1' or print "# k[$_]=$k[$_], pc[$_]=$pc[$_]\nnot ";
  if ($pc[$_]) {
    my $kind = $tc[$_]->parameter_type_kind($ev,0);
    print "# 1st parameter kind=$kind (in XS).\n";
    my $par = $tc[$_]->parameter($ev,0);
    my $t = $par->type($ev);
    my $k = $t->kind($ev);
    print "# 1st parameter kind=$k.\n";
    my $v = $par->value($ev);
    print "# 1st parameter value='$v'.\n";
  }
  $test = $_ + 25;
  print "ok $test\n";
}

