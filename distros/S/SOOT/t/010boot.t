use strict;
use warnings;
use Test::More tests => 19;
use SOOT;
pass();
is_deeply(\@TH1D::ISA, ["TH1"]);

eval { TObject->new(qw(a b c)); };
ok($@ && "$@" =~ /Can't locate method/, "Can't locate method...");
#diag($@) if $@;

eval { TH1D->Foo(); };
ok($@ && "$@" =~ /Can't locate method/, "Can't locate method...");
#diag($@) if $@;

TODO: {
  local $TODO = "TAdvancedGraphicsDialog isn't loaded by default => need to figure out dynamic .so loading";
  eval { TAdvancedGraphicsDialog->DoesntExist(); };
  ok($@ && "$@" =~ /Can't locate method/, "Can't locate method...");
  #diag($@) if $@;
}

my $tgraph = eval { TGraph->new(12); };
#my $tgraph = eval { TGraph->new(3, [1.,2,3], [1.,2,3]); };
ok(!$@, "No error on TGraph->new");
diag($@) if $@;

ok(defined $tgraph);
isa_ok($tgraph, 'TGraph');
isa_ok($tgraph, 'TObject');

my $n = eval { $tgraph->GetN(); };
ok(!$@, "No error on TGraph->GetN");
ok((defined $n) && ($n == 12), "GetN works!");
undef $tgraph;

$tgraph = eval { TGraph->new(3, [1., 2., 4.], [0.5, 20., 10.]); };
ok(!$@, "No error on full TGraph->new");
diag($@) if $@;

ok(defined $tgraph);
isa_ok($tgraph, 'TGraph');
isa_ok($tgraph, 'TObject');

$n = eval { $tgraph->GetN(); };
ok(!$@, "No error on TGraph->GetN") or diag("Error: $@");
is($n, 3, "GetN works!");
my $ary = $tgraph->GetX();
is_deeply($ary, [1.,2.,4.]);

undef $tgraph;

pass("alive");

