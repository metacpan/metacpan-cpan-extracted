#!/usr/bin/perl

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Cache';
}

BEGIN { $t->use_ok('Set::Files'); }
$testdir = $t->testdir();

$q = new Set::Files("path"          => ["$testdir/dir1a","$testdir/dir1b"],
                    "types"         => ["type1","type2"],
                    "default_types" => "none",
                    "read"          => "files",
                    "cache"         => $testdir,
                   );
$q->cache;

$c = new Set::Files("path"          => ["$testdir/dir1a","$testdir/dir1b"],
                    "types"         => ["type1","type2"],
                    "default_types" => "none",
                    "read"          => "cache",
                    "cache"         => $testdir,
                   );

@tests = (
          [$c->list_sets()],            [qw(a b c)],
          [$c->list_sets("type1")],     [qw(a b)],
          [$c->members("a")],           [qw(a ab abc ac b)],
          [$c->members("b")],           [qw(ab abc b bc)],
          [$c->is_member("a","ab")],    [1],
          [$c->is_member("a","c")],     [0],
          [$c->list_types()],           [qw(type1 type2)],
          [$c->list_types("a")],        [qw(type1 type2)],
          [$c->list_types("b")],        [qw(type1)],
          [$c->dir("a")],               ["$testdir/dir1a"],
          [$c->dir("c")],               ["$testdir/dir1b"],
          [$c->opts("a","a1")],         [1],
          [$c->opts("a","a2")],         [qw(vala2)]
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

unlink "$testdir/.set_files.cache";

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

