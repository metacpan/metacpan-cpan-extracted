#!/usr/bin/perl

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Valid File';
}

BEGIN { $t->use_ok('Set::Files'); }
$testdir = $t->testdir();

sub valid_file {
  my($dir,$file) = @_;
  return 1  if ($file eq "a1"  ||  $file eq "b2");
  return 0;
}

sub test {
   my($valid) = @_;

   my $q = new Set::Files("path"          => "$testdir/dir4",
                          "invalid_quiet" => 1,
                          "valid_file"    => $valid
                         );
   $q->list_sets();
}

$t->tests(func     => \&test,
          tests    => [ '^a',        '2$',        '!^a',       '!2$',       \&valid_file],
          expected => [ [qw(a1 a2)], [qw(a2 b2)], [qw(b1 b2)], [qw(a1 b1)], [qw(a1 b2)] ]);
$t->done_testing();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

