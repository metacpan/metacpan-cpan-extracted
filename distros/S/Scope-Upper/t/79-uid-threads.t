#!perl

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers (
 threads => [ 'Scope::Upper' => 'Scope::Upper::SU_THREADSAFE()' ],
 'usleep',
);

use Test::Leaner;

use Scope::Upper qw<uid validate_uid UP HERE>;

my $top = uid;

sub cb {
 my $tid  = threads->tid();

 my $here = uid;
 my $up;
 {
  $up = uid HERE;
  is uid(UP), $here, "uid(UP) == \$here in block (in thread $tid)";
 }

 is uid(UP), $top, "uid(UP) == \$top (in thread $tid)";

 usleep rand(2.5e5);

 ok validate_uid($here), "\$here is valid (in thread $tid)";
 ok !validate_uid($up),  "\$up is no longer valid (in thread $tid)";

 return $here;
}

my %uids;
my $threads = 0;
for my $thread (map spawn(\&cb), 1 .. 30) {
 my $tid = $thread->tid;
 my $uid = $thread->join;
 if (defined $uid) {
  ++$threads;
  ++$uids{$uid};
  ok !validate_uid($uid), "\$here is no longer valid (out of thread $tid)";
 }
}

is scalar(keys %uids), $threads, 'all the UIDs were different';

done_testing;
