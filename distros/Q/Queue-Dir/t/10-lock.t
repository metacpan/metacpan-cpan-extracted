# This -*- perl -*- code tests the locking code

use File::Path;
use Queue::Dir;
use Test::More tests => 8;

END { rmtree (["test$$"]); }

				# Test the ->new calls

mkdir "test$$";

my $q = new Queue::Dir paths => [ '.' ], lockdir => 'lock';

ok(defined $q, 'Proper ->new()');

$q = new Queue::Dir paths => [ "test$$" ], lockdir => 'lock';

ok(defined $q, 'Proper ->new() with a path');

$q = undef;

eval { $q = new Queue::Dir paths => [ "not$$" ], lockdir => 'lock' };

ok(! defined $q, '->new() with unexistant path');

				# Test that lock files are really
				# being created
# $Queue::Dir::Debug = 1;
$q = new Queue::Dir paths => [ "test$$" ], lockdir => 'lock';

my ($fh, $qid) = $q->store;
print $fh "Hello World! ($$)\n";
$fh->close;

ok(-f "test$$/lock/$qid", "lockfile is present");
$q->unlock;
ok(!-f "test$$/lock/$qid", "lockfile automatically removed by unlock()");
$q->done($qid);

				# Test that locks don't allow 
				# interference between queues

$q1 = new Queue::Dir paths => [ "test$$" ], lockdir => 'lock';

my ($fh, $qid) = $q1->store;
print $fh "Hello World! ($$)\n";
$fh->close;

$q2 = new Queue::Dir paths => [ "test$$" ], lockdir => 'lock';

my $nid = undef;

$fh = $q2->visit;
#warn "1st ->visit returns $nid\n";

ok(!$fh, "->visit does not report locked objects");

$fh = $q2->visit;
#warn "2nd ->next returns $nid\n";

ok(!$fh, "->visit still does not report locked objects");

$q1->unlock;

$fh = $q2->visit;
ok($fh, "->next returns newly unlocked object");

$q1->done($qid);




