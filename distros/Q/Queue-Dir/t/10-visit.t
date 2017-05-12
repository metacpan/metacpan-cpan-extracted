# This is -*- perl -*-
use File::Path;
use Queue::Dir;
use Test::More tests => 34;

END { rmtree(["t$$-a"]); }

mkdir "t$$-a";

				# Test a plain ->new()

my $q = new Queue::Dir id => 'test', paths => [ "t$$-a" ];
ok(defined $q, 'Proper ->new()');

				# Test if a store() succeeds and
				# its results are a writeable file
for my $count (1..5)
{
    my ($fh, $qid) = $q->store;
    ok(ref $fh eq 'IO::File', 'Proper file opened');
    ok(defined $qid, "Queue id $qid was assigned");
    $store{$qid} = "Hello World ($count)\n";
    print $fh $store{$qid};
    $fh->close;
}

$q = undef;			# Wipe the older queue

				# Open a new one on the same space
$q = new Queue::Dir id => 'test', paths => [ "t$$-a" ];
ok(defined $q, 'Proper ->new()');

				# Read things seven times to test the proper
				# recycling of the entries
$fh = $q->visit;
ok(ref $fh eq 'IO::File', "Proper fh");
ok(defined $q->next, "->next is defined");
#warn $fh->getlines;

$fh = $q->visit;
ok(ref $fh eq 'IO::File', "Proper fh");
ok(defined $q->next, "->next is defined");
#warn $fh->getlines;

$fh = $q->visit;
ok(ref $fh eq 'IO::File', "Proper fh");
ok(defined $q->next, "->next is defined");
#warn $fh->getlines;

$fh = $q->visit;
ok(ref $fh eq 'IO::File', "Proper fh");
ok(defined $q->next, "->next is defined");
#warn $fh->getlines;

$fh = $q->visit;
ok(ref $fh eq 'IO::File', "Proper fh");
ok(!defined($q->next), "->next is undefined");
#warn $fh->getlines;

$fh = $q->visit;
ok(ref $fh eq 'IO::File', "Proper fh");
ok($q->next, "->next is undefined");

				# At this point, we have a complete cycle of
				# the queue. Let's see if we can remove a
				# random entry...

my $key = (keys %store)[0];
$q->done($key);
delete $store{$key};
$q->next;

for my $count (1..4)
{
    $fh = $q->visit;
    ok(ref $fh eq 'IO::File', "Proper fh");
    my $text = $fh->getline;
    ok((grep { $text eq $_ } values %store), "Proper text");
}
				# Wipe the queue objects

$q->done($_) for keys %store;

ok(!defined($q->next), "->next is undefined");
ok(!defined($q->next), "->next is undefined");
