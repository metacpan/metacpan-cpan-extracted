# This is -*- perl -*- code to excercise the queue walking stuff.

# $Id: 20-walk.t,v 1.3 2003/06/30 17:22:07 lem Exp $

use File::Path;
use Queue::Dir;
use Test::More tests => 5;

END { rmtree(["t$$"]); }

mkdir "t$$";

my $q = new Queue::Dir id => 'test', paths => [ "t$$" ];
ok(defined $q, 'Proper ->new()');

my ($fh, $qid) = $q->store;

print $fh "Hello World!\n";

$fh->close;

my $nqid = $q->next;

ok(! defined $nqid, "->next on empty queue is undef");

$nqid = $q->next;

ok($nqid eq $qid, "->next wraps queue");

$nqid = $q->next;

ok(! defined $nqid, "->2nd next on empty queue is still undef");

$nqid = $q->next;

ok($nqid eq $qid, "->next wraps queue 2nd time");

$q->done($nqid);
