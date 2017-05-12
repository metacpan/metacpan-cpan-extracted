# This is -*- perl -*- code to excercise concurrent ->visit()

# $Id: 20-visit.t,v 1.2 2003/06/30 17:22:07 lem Exp $

use File::Path;
use Queue::Dir;
use Test::More tests => 5;

END { rmtree(["t$$"]); }

mkdir "t$$";

my $q = new Queue::Dir id => 'test', paths => [ "t$$" ];
ok(defined $q, 'Proper ->new()');

my ($fh, $qid1) = $q->store;

print $fh "First\n";

$fh->close;

my ($fh2, $qid2) = $q->store;

print $fh2 "Second\n";

$fh2->close;

ok(unlink "t$$/$qid2", "unlink() of queue file");

$q->next;

my $qid = $q->next;

ok($qid eq $qid1, "->next must point to remaining file");

$fh = $q->visit();

ok(defined $fh, "->visit must not fail");

ok($fh->getline eq "First\n", "Correct file contents");

$fh->close;

$q->done($qid1);
$q->done($qid2);
