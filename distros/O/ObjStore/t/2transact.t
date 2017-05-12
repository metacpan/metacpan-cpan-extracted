# test all transaction types for -*-perl-*-
use Test;
BEGIN { plan tests => 18 }

use strict;
use ObjStore ':ALL';
use ObjStore::Config;
use lib './t';
use test;

#ObjStore::debug qw(txn);

#my $tsys = 'ObjStore::Transaction';
sub txn() { ObjStore::Transaction::get_current() }

&open_db;

ObjStore::fatal_exceptions(0);
$ObjStore::TRANSACTION_PRIORITY = 0;

for ('read','write') {
    my $t = 5.5;
    lock_timeout($_, $t);
    ok(lock_timeout($_), $t);
}

eval { &ObjStore::lookup($ObjStore::Config::TMP_DBDIR . "/bogus.db", 0); };
ok($@ =~ m/does not exist/) or warn $@;

# make sure the tripwire is ready
begin 'update', sub {
    my $s = $db->create_segment('tripwire');
    $db->root("tripwire", sub {new ObjStore::HV($s, 7)});
};
die if $@;

begin 'update', sub {
    ok($db->is_writable);
    ok(txn->get_type, 'update');

    my $john = $db->root('John');
    $john->{right} = 69;
    ok ObjStore::get_lock_status($john), 'write';
    
    ok(! ObjStore::is_lock_contention);

#    txn->prepare_to_commit;
#    ok(txn->is_prepare_to_commit_invoked);
#    txn->is_prepare_to_commit_completed;
};
die if $@;

begin 'abort', sub {
    ok($db->is_writable);
    ok(txn->get_type, 'abort_only');
    my $john = $db->root('John');
    $john->{right} = 96;
};
die if $@;

begin('read', sub {
    ok(! $db->is_writable);
    ok(txn->get_type(), 'read');
    my $john = $db->root('John');
    ok(ObjStore::get_lock_status($john), 'read');

    eval { $john->{'write'} = 0; };
    ok($@ =~ m/Attempt to write during a read-only/) or warn $@;

    ok($john->{right}, 69);
});
ok(! $@);

begin('update', sub {
    my $j = $db->root('John');
    begin('update', sub {
	$j->{oopsie} = [1,2];
	die 'undo';
    });
    warn $@ if $@ !~ m'^undo';
    ok(! exists $j->{oopsie});
});
ok(! $@);

if (0) {
my $debug =0;

# retry deadlock
set_max_retries(10);
my $retry=0;
my $attempt=0;
begin 'update', sub {
    ++ $retry;

    my $right = $db->root('John');
    ++ $right->{right};
    warn "[1]right\n" if $debug;

    my $code = sub {
	warn "begin bogus code" if $debug;
	my $quiet = 1? '2>/dev/null':'';
	system("$^X -Mblib t/deadlock.pl 1>/dev/null $quiet &");
	warn "[1]sleep\n" if $debug;
	sleep 6;
	warn "[1]left\n" if $debug;
	my $left = $db->root('tripwire');
	$left->{left} = 0;
	$left->{left} = $right->{right};
    };
    ++ $attempt;
    warn "attempt $attempt retry $retry" if $debug;
    if ($attempt == 1) {
	&$code;
	die "Didn't get deadlock";
    } elsif ($attempt == 2) {
	begin 'update', \&$code;
	die if $@;
    } else { 1 }
};
warn $@ if $@;
ok($attempt,3);
}
