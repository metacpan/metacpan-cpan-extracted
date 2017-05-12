# This is -*- perl -*- code to excercise ->done()

# $Id: 20-done.t,v 1.3 2003/06/30 17:22:07 lem Exp $

use File::Path;
use Queue::Dir;
use Test::More tests => 3;

END { rmtree(["t$$"]); }

mkdir "t$$";

my $q = new Queue::Dir id => 'test', paths => [ "t$$" ];
ok(defined $q, 'Proper ->new()');

my ($fh, $qid) = $q->store;

print $fh "Hello World!\n";

$fh->close;

$q->done($qid);			# Wipe the object

$qid = $q->next;

ok(! defined $qid, "->next must not return anything");

$fh = $q->visit("w", $qid);

ok(! defined $fh, "->visit must fail for unexistant object");
