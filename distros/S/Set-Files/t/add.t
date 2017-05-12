#!/usr/bin/perl

BEGIN {
  use Test::Inter;
  $t = new Test::Inter '';
}

BEGIN { $t->use_ok('Set::Files'); }
$testdir = $t->testdir();

sub init {
   $q = new Set::Files("path"          => ["$testdir/dir2a","$testdir/dir2b"],
                       "types"         => ["type1","type2"],
                       "invalid_quiet" => 1,
                       "default_types" => "none"
                      );
   return;
}

@tests = (
          [init(),
           $q->members("a")],               [qw(a ab abc b)],

          [init(),
           $q->add("a",0,0, "b","y","z"),
           $q->members("a")],               [2,qw(a ab abc b y z)],

          [init(),
           $q->add("a",1,0, "b","y","z"),
           $q->members("a")],               [3,qw(a ab abc b y z)],

          [init(),
           $q->add("a",0,0, "ac","b","y","z"),
           $q->members("a")],               [3,qw(a ab abc ac b y z)],

          [init(),
           $q->add("a",1,0, "ac","b","y","z"),
           $q->members("a")],               [4,qw(a ab abc ac b y z)],

          [init(),
           $q->add("a",0,0, "b","y","z"),
           $q->remove("a",0,0, "ab","y","yy"),
           $q->members("a")],               [2,2,qw(a abc b z)],

          [init(),
           $q->add("a",0,0, "b","y","z"),
           $q->remove("a",1,0, "ab","y","yy"),
           $q->members("a")],               [2,3,qw(a abc b z)],

          [init(),
           $q->add("a",0,0, "ac"),
           $q->members("a")],               [1,qw(a ab abc ac b)],

          [init(),
           $q->add("a",0,0, "bc"),
           $q->members("a")],               [1,qw(a ab abc b bc)]
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

