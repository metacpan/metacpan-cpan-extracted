# This -*- perl -*- code tests ->next

use File::Path;
use Queue::Dir;
use Test::More tests => 10;

END { rmtree (["test$$"]); }

mkdir "test$$";

				# Without locks

my $q = new Queue::Dir paths => [ "test$$" ];

my ($fh, $qid) = $q->store;

print $fh "Hello World!\n";

$fh->close;

$q = new Queue::Dir paths => [ "test$$" ];

ok($q->next eq $qid, "->next returns a ready object");
ok(!defined $q->next, "->next wraps queue around");
ok($q->next eq $qid, "2nd ->next returns a ready object");

$q->done($qid);

ok(!defined $q->next, "->next returns on an empty queue");
ok(!defined $q->next, "->next returns on an empty queue");

				# With locks

$q = new Queue::Dir paths => [ "test$$" ], lockdir => 'lock';

($fh, $qid) = $q->store;

print $fh "Hello World!\n";

$fh->close;

$q->unlock;

$q = new Queue::Dir paths => [ "test$$" ], lockdir => 'lock';

ok($q->next eq $qid, "->next returns a ready object");
ok(!defined $q->next, "->next wraps queue around");
ok($q->next eq $qid, "2nd ->next returns a ready object");

$q->done($qid);

ok(!defined $q->next, "->next returns on an empty queue");
ok(!defined $q->next, "->next returns on an empty queue");


