# $Id: password_hash.t,v 1.1 2017/06/21 19:29:22 cmanley Exp $
# This file must be saved in UTF-8 encoding!
use strict;
use warnings;
use Test::More; #qw(no_plan);
use lib qw(../lib);

my @test_passwords = (
	'hello',
	'Test 123',
	'€U maffia',
);

my @methods = map { $_, "password_$_"; } qw(
	hash
	verify
);

my $php;
if (!($ENV{'HARNESS_ACTIVE'} || ($^O eq 'MSWin32'))) {	# experimental: that's why it's only executed when not in a test harness
	$php = `which php`;
	$php =~ s/^\s+|\s+$//g;
	if (-x $php) {
		my $phpversion = `php -v`;
		$phpversion =~ s/^PHP (\S+)\s.*/$1/s;
		if ($phpversion =~ /^(\d{1,3}\.\d{1,6})\b/) {
			if ($1 < 5.5) {
				undef($php);
			}
		}
		print "Found PHP executable $php with version $phpversion: " . ($php ? 'OK' : 'TOO OLD') . "\n";
	}
	else {
		undef($php);
	}
}

plan tests => 1 + scalar(@methods) + ($php ? 4 : 3) * scalar(@test_passwords);
my $class = 'PHP::Functions::Password';
require_ok($class) || BAIL_OUT("$class has errors");
foreach my $method (@methods) {
	can_ok($class, $method);
	if ($method =~ /^password/) {
		$class->import($method);
	}
}

foreach my $password (@test_passwords) {
	my $crypted = $class->hash($password);
	ok(length($crypted) eq 60, "$class->hash(\"$password\") returns a crypted string");

	my $result = $class->verify($password, $crypted);
	ok($result, "Expect success from verify method using password \"$password\" and new crypted string \"$crypted\"");

	$result = password_verify($password, $crypted);
	ok($result, "Expect success from password_verify function using password \"$password\" and new crypted string \"$crypted\"");

	if ($php) {
		my $phpcode = "var_export(password_verify('" . $password . "', '" . $crypted . "'));";
		my $h;
		open($h, '-|', $php, '-r', $phpcode) || die("Failed to execute $php: $!");
		my $line = <$h>;
		close($h);
		ok($line eq 'true', "Expect true from PHP's password_verify(\"$password\", \"$crypted\")");
	}
}
