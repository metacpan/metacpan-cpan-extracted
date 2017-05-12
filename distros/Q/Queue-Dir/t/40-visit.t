# This -*- perl -*- code tests visiting concurrent queues

use File::Path;
use Queue::Dir;
use Test::More tests => 4;

END { rmtree ([ "test$$" ]); }

mkdir "test$$";

				# Prime the queue with 2 objects

my $q = new Queue::Dir paths => [ "test$$" ], lockdir => 'lock';

my ($fh1, $qid1) = $q->store;

print $fh1 $qid1, "\n";

$fh1->close;
$q->unlock;


my ($fh2, $qid2) = $q->store;

print $fh2 $qid2, "\n";

$fh2->close;
$q->unlock;

				# ->visit() must now return one of the
				# objects

my ($rfh1, $rfh2, $rfh3) = sort ($q->visit, $q->visit, $q->visit);

chomp(my $rstr1 = $rfh2->getline);
chomp(my $rstr2 = $rfh3->getline);

ok(! defined $rfh1, "Correct queue wrap around");

ok($rstr1 ne $rstr2, "Different objects returned");
ok(grep { $rstr1 eq $_ } ($qid1, $qid2), 
   "Correct contents for the first object");
ok(grep { $rstr2 eq $_ } ($qid1, $qid2), 
   "Correct contents for the first object");

$q->next;
$q->next;

while ($q->next)
{
    $q->done;
}
