#! /usr/bin/perl -w

#
# test callbacks
#

use Test;
use Fcntl;

BEGIN { plan tests => 18 };

use TDB_File;

my $tdb = TDB_File->open("test.tdb", TDB_CLEAR_IF_FIRST)
  or die "Couldn't open test.tdb: $!";

$tdb->store(arg1 => 'val1');
$tdb->store(arg2 => 'val2');
$tdb->store(arg3 => 'val3');

my %found;
ok($tdb->traverse(sub { $found{$_[0]} = $_[1] }), 3);
ok($found{arg1}, 'val1');
ok($found{arg2}, 'val2');
ok($found{arg3}, 'val3');

# test coderef return value (false means stop)
ok($tdb->traverse(sub { 0 }), 1);

# test undef coderef (should simply return keys count)
ok($tdb->traverse, 3);


# trigger constructor log callback
# (O_WRONLY is an error)
my ($level, $msg);
ok(!TDB_File->open("test.tdb", TDB_DEFAULT, O_WRONLY, 0666, 0,
		   sub { ($level, $msg) = @_ }));
ok($level, 0);
ok($msg);


# test separate logging functions

my ($called1, $called2);
$called1 = $called2 = 0;

my $tdb1 = TDB_File->open("test1.tdb");
ok($tdb1);
$tdb1->logging_function(sub { $called1++ });

my $tdb2 = TDB_File->open("test2.tdb");
ok($tdb2);
$tdb2->logging_function(sub { $called2++ });

# reopen after unlink should trigger a logged error
ok(unlink(qw(test1.tdb test2.tdb)), 2);

ok(!$tdb1->reopen);
ok($called1, 1);
ok($called2, 0);

ok(!$tdb2->reopen);
ok($called2, 1);


# hash callback

$tdb = TDB_File->open("dummy.tdb", TDB_INTERNAL, O_RDWR, 0666, 0, undef,
		      sub { ord substr $_[0], 0, 1 })
  or die "Couldn't open test3.tdb: $!";

ok($tdb);
$tdb->store(ant => 'val1');
$tdb->store(apple => 'val2');
$tdb->store(banana => 'val3');

# FIXME: this shows the right thing (two records with the one hash
# value (97) and one record with another (98)), just have to find a
# way to machine test that..
#$tdb->dump_all;
