use strict;
use warnings;
use Test::More tests => 9;
use SOOT qw/:all/;

my $name = "foo";
sub foo {
  pass($name);
}
my $barcalled = 0;
sub bar {
  $barcalled = 1;
  pass($name);
}

$gApplication->Init();
SCOPE: {
  my $texec = TExec->new("test", qq{SOOT::TExecImpl::TestAlive();\n});
  isa_ok($texec, 'TExec');
  $texec->Exec();
  pass();

  $name = "Explicit exec";
  $texec->Exec(\&foo);
}

SCOPE: {
  my $texec = TExec->new("test2", \&foo);
  isa_ok($texec, 'TExec');
  $name = "Exec via constructor / default";
  $texec->Exec();
  is($barcalled, 0);
  $texec->SetAction(\&bar);
  is($barcalled, 0);
  $texec->Paint();
  is($barcalled, 1);
}

