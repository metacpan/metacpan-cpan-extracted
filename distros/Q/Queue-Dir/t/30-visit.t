# This -*- perl -*- code tests visiting concurrent queues

use File::Path;
use Queue::Dir;
use Test::More tests => 5;

END { rmtree ([ "test$$" ]); }

mkdir "test$$";

				# Prime the queue with 2 objects

my $q1 = new Queue::Dir paths => [ "test$$" ], lockdir => 'lock';
my $q2 = new Queue::Dir paths => [ "test$$" ], lockdir => 'lock';

my ($fh1, $qid1) = $q1->store;

print $fh1 $qid1, "\n";

$fh1->close;
$q1->unlock;


my ($fh2, $qid2) = $q1->store;

print $fh2 $qid2, "\n";

$fh2->close;
$q1->unlock;

				# Now, use another object to extract
				# the second object.

my $fht1 = $q1->visit;
#$Queue::Dir::Debug = 1;
my $fht2 = $q2->visit;
#$Queue::Dir::Debug = 0;

ok($fht1, "1st Normal fetch + lock");
ok($fht2, "2nd Normal fetch + lock");

my @ids = ($qid1, $qid2);

chomp(my $id1 = $fht1->getline);
chomp(my $id2 = $fht2->getline);

ok($id1 ne $id2, "Got different files");
ok(grep($_ eq $id1, @ids), "First file was ok");
ok(grep($_ eq $id2, @ids), "First file was ok");

$q1->next;

while ($q1->next)
{
    $q1->done;
}
