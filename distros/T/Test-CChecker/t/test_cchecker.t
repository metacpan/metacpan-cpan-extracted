use strict;
use warnings;
use Test::More;
use Test::CChecker;

cc;

sub c ($)
{
  my $fh;
  open $fh, '<', "corpus/$_[0].c";
  my $source = do { local $/; <$fh> };
  close $fh;
  $source;
}

subtest 'basic' => sub {

  my $r;

  $r = compile_run_ok c 'foo1', "basic compile test";
  ok $r, 'returns okay';

  $r = compile_run_ok { extra_compiler_flags => ['-DFOO_BAR_BAZ=1'], source => c 'foo2' }, "define test";
  ok $r, 'returns ok';

};

subtest 'compile only' => sub {

  my $r;

  $r = compile_ok c 'foo3', "basic compile only test";
  ok $r, 'returns okay';

  $r = compile_ok { extra_compiler_flags => ['-DFOO_BAR_BAZ=1'], source => c 'foo4' }, "define test";
  ok $r, 'returns ok';

};

subtest 'cc' => sub {

  my $cc = cc;
  
  isa_ok $cc, 'ExtUtils::CChecker';

};

done_testing;
