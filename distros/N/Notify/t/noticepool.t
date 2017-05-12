#!/usr/bin/perl

# tests the notice pool with no transports

BEGIN { $Test::Harness::verbose++; $|++; print "1..2\n"; }
END   { print "not ok\n", exit 1 unless $loaded; }

use Notify::Notice;
use Notify::NoticePool;

$loaded = 1;

print "ok\n";

eval {

	my $notice = new Notify::Notice;

	my $pool = new Notify::NoticePool ({
		'file_store' => "./.test_db",
		'transport' => { },
	});

	undef $pool;

	unlink ("./.test_db");

};

$Test::Harness::verbose += 1;

if ($@) {

	print STDERR "not ok:  $@";
	exit 1;

}
else {

	print "ok\n";
	exit 0;

}
