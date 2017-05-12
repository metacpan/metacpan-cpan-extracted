#!perl -w
# checks we're handling references correctly in XS
# or tries to
use strict;

use Test::More tests => 37;

my $counter = 'AA';

BEGIN { use_ok("POE::XS::Queue::Array") }

my %released;

my ($obj, $value) = Counter->new;

my $q = POE::XS::Queue::Array->new;

print "# trivial one item and dequeue it\n";
$q->enqueue(100, $obj);
undef $obj;
ok(!$released{$value}, "check it's not released too early");
$q->dequeue_next; # important we discard this
ok($released{$value}, "or too late in void context dequeue");

%released = ();
($obj, $value) = Counter->new;
# do it in list context
$q->enqueue(101, $obj);
undef $obj;
ok(!$released{$value}, "check early release for list dequeue");
my @res = $q->dequeue_next;
ok(!$released{$value}, "check early release for list dequeue (in array)");
undef @res;
ok($released{$value} == 1, "should be free now");
is(keys %released, 1, "check only one released");

print "# remove single item - item at the front - void context\n";
%released = ();
($obj, $value) = Counter->new;
my ($obj2, $value2) = Counter->new;
my $id = $q->enqueue(102, $obj);
my $id2 = $q->enqueue(103, $obj2);
undef $obj;
undef $obj2;
ok(!$released{$value}, "check neither ...");
ok(!$released{$value2}, "... has been released");
$q->remove_item($id, sub { 1 });
ok($released{$value}, "check it's released");
ok(!$released{$value2}, "and other isn't");
is(keys %released, 1, "check only one released");
is($q->get_item_count, 1, "check count");

print "# remove single item - item at the front - list context\n";
%released = ();
($obj, $value) = Counter->new;
#my ($obj2, $value2) = Counter->new; # already in the queue
$id = $q->enqueue(102, $obj);
# my $id2 = $q->enqueue(103, $obj2); already in the queue
undef $obj;
# undef $obj2; done already
ok(!$released{$value}, "check neither ...");
ok(!$released{$value2}, "... has been released");
@res = $q->remove_item($id, sub { 1 });
undef @res;
ok($released{$value}, "check it's released");
ok(!$released{$value2}, "and other isn't");
is(keys %released, 1, "check only one released");

# list/void context doesn't matter here - it's handled in the XS code and
# is tested above
print "# remove single item - item at the end\n";
%released = ();
($obj, $value) = Counter->new;
$id = $q->enqueue(104, $obj);
undef $obj;
ok(!$released{$value}, "check not released yet");
$q->remove_item($id, sub { 1 });
ok($released{$value}, "check it was released");
ok(!$released{$value2}, "and other isn't");
is(keys %released, 1, "check only one released");

print "# remove single item - item in the middle\n";
%released = ();
($obj, $value) = Counter->new;
my ($obj3, $value3) = Counter->new;
$id = $q->enqueue(102, $obj);
my $id3 = $q->enqueue(104, $obj3);
undef $obj;
undef $obj3;
$q->remove_item($id2, sub { 1 });
ok($released{$value2}, "check it was released");
ok(!$released{$value}, "and others ...");
ok(!$released{$value3}, "... weren't");

print "# peek at the contents\n";
%released = ();
@res = $q->peek_items(sub { 1 });
is(keys %released, 0, "check nothing released");
undef @res;
is(keys %released, 0, "still nothing released");
$q->remove_item($id, sub { 1 });
ok($released{$value}, "check one released");
$q->remove_item($id3, sub { 1 });
ok($released{$value3}, "check other released");
is(keys %released, 2, "check nothing else released");

print "# bulk removal\n";
%released = ();
($obj, $value) = Counter->new;
($obj2, $value2) = Counter->new;
($obj3, $value3) = Counter->new;
$q->enqueue(101, $obj);
$q->enqueue(103, $obj2);
$q->enqueue(102, $obj3);
undef $obj;
undef $obj2;
undef $obj3;
@res = $q->remove_items(sub { ${$_[0]} eq $value3 });
is(keys %released, 0, "nothing released yet");
undef @res;
ok($released{$value3}, "check it was released");
is(keys %released, 1, "and nothing else");
# remove the rest
$q->remove_items(sub { 1 });
ok($released{$value}, "check both ...");
ok($released{$value2}, "... have been released");
is(keys %released, 3, "and nothing else");
is($q->get_item_count, 0, "and queue is empty");

# priority adjustments
%released = ();
($obj, $value) = Counter->new;
($obj2, $value2) = Counter->new;
($obj3, $value3) = Counter->new;
$q->enqueue(101, $obj);
$q->enqueue(102, $obj2);
$q->enqueue(103, $obj3);
undef $obj;
undef $obj2;
undef $obj3;


# test class used to track destruction
sub Counter::new {
  my $foo = $counter++;
  print "# created $foo\n";
  if (wantarray) {
    return ( (bless \$foo, shift), $foo );
  }
  else {
    return bless \$foo, shift;
  }
}

sub Counter::value { ${$_[0]} }

sub Counter::DESTROY { 
  print "# destroyed ${$_[0]}\n";
  ++$released{${$_[0]}}
}
