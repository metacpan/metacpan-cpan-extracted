#!/usr/bin/perl

# tests the Email transport

BEGIN { $Test::Harness::verbose++; $|++; print "1..2\n";}
END   { print "not ok\n", exit 1 unless $loaded; }

use Notify::Notice;
use Notify::Email;

$loaded = 1;

print "ok\n";

eval {

	my $notice = new Notify::Notice;

	my $transport = new Notify::Email ({
		'app' => 'CPAN test',
		'mbox' => "./mbox",
		'smtp' => 'localhost',
	});

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
