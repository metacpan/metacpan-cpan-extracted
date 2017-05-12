#!perl

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers (
 threads => [ 'Scope::Upper' => 'Scope::Upper::SU_THREADSAFE()' ],
 'usleep',
);

use Test::Leaner;

use Scope::Upper qw<yield UP>;

our $z;

sub up1 {
 my $tid  = threads->tid();
 local $z = $tid;
 my $p    = "[$tid] up1";

 usleep rand(2.5e5);

 my @res = (
  -1,
  do {
   my @dummy = (
    999,
    map {
     my $foo = yield $tid .. $tid + 2 => UP;
     fail "$p: not reached";
    } 666
   );
   fail "$p: not reached";
  },
  -2
 );

 is_deeply \@res, [ -1, $tid .. $tid + 2, -2 ], "$p: yielded correctly";

 return 1;
}

my @threads = map spawn(\&up1), 1 .. 30;

my $completed = 0;
for my $thr (@threads) {
 ++$completed if $thr->join;
}

pass 'done';

done_testing($completed + 1);
