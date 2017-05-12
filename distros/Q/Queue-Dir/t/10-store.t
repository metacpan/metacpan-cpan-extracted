# This is -*- perl -*-
use IO::File;
use File::Path;
use Queue::Dir;
use Test::More tests => 59;

END { rmtree (["t$$-a", "t$$-b"]); }

mkdir "t$$-a";
mkdir "t$$-b";

				# Test a plain ->new()

my $q = new Queue::Dir id => 'test', paths => [ "t$$-a" ];
ok(defined $q, 'Proper ->new()');

				# Test if a store() succeeds and
				# its results are a writeable file
my ($fh, $qid) = $q->store;
ok(ref $fh eq 'IO::File', 'Proper file opened');
ok(defined $qid, "Queue id $qid was assigned");
print $fh "Hello World\n";
$fh->close;

				# Test if we can read (under the table)
				# the queue file and verify that its
				# contents are readable
ok($fh->open("t$$-a/$qid", "r"), 'Open of queue file');
my $str = $fh->getline;
ok(index($str, 'Hello World') == 0, 'File contents are ok');
$fh->close;
unlink("t$$-a/$qid");

				# Now test the storage of objects in both
				# dirs

$q = new Queue::Dir id => 'test', paths => [ "t$$-a", "t$$-b" ];
ok(defined $q, 'Proper ->new()');

				# Store 4 files in the queue

my @q = ();

for my $count (1 .. 10)
{
    my ($fh, $qid) = $q->store;
    ok(ref $fh eq 'IO::File', "Proper file opened for count $count");
    ok(defined $qid, "Queue id $qid was assigned to item $count");
    print $fh "Count = $count\n";
#    warn "qid $qid name ", $q->name($qid), "\n";
    push @q, [ $qid, $q->name($qid) ];
    $fh->close;
}

my %h = ();

for my $i (@q)
{
    my ($name, $id) = split(m!/!, $i->[1]);
    $h{$name}++;
}

ok($h{"t$$-a"} == 5, "Elements in first queue");
ok($h{"t$$-b"} == 5, "Elements in second queue");
ok(@{$h{"t$$-a"}} == @{$h{"t$$-b"}}, "Round robin seems ok");

				# Verify the pathnames...
for my $i (@q)
{
#    warn "i $i->[1], qid $i->[0], name ", $q->name($i->[0]), "\n";
    my $name = $q->name($i->[0]);
    ok($i->[1] eq $name, "Correct path for $i->[0]");
    ok(-f $q->name($i->[0]), "$i->[0] has a corresponding file");
    $q->done($i->[0]);		# Wipe the queue file
    ok(! -f $name, "corresponding file for $i->[0] collected");
}

