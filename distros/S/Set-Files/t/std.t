#!/usr/bin/perl

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Standard';
}

BEGIN { $t->use_ok('Set::Files'); }
$testdir = $t->testdir();

$q = new Set::Files("path"          => ["$testdir/dir1a","$testdir/dir1b"],
                    "types"         => ["type1","type2"],
                    "default_types" => "none"
                   );

@tests = (
          [$q->list_sets()],            [qw(a b c)],
          [$q->list_sets("type1")],     [qw(a b)],
          [$q->members("a")],           [qw(a ab abc ac b)],
          [$q->members("b")],           [qw(ab abc b bc)],
          [$q->is_member("a","ab")],    [1],
          [$q->is_member("a","c")],     [0],
          [$q->list_types()],           [qw(type1 type2)],
          [$q->list_types("a")],        [qw(type1 type2)],
          [$q->list_types("b")],        [qw(type1)],
          [$q->dir("a")],               ["$testdir/dir1a"],
          [$q->dir("c")],               ["$testdir/dir1b"],
          [$q->opts("a","a1")],         [1],
          [$q->opts("a","a2")],         [qw(vala2)]
         );
@results  = ();
@expected = ();
while (@tests) {
   push(@results,shift(@tests));
   push(@expected,shift(@tests));
}

$t->tests(tests    => [ @results ],
          expected => [ @expected ]);

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

