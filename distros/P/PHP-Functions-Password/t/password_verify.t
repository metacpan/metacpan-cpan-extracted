# $Id: password_verify.t,v 1.2 2017/06/24 13:25:32 cmanley Exp $
# This file must be saved in UTF-8 encoding!
use strict;
use warnings;
use Test::More;
use lib qw(../lib);
use PHP::Functions::Password;

my %tests_verify_good = (
	'hello'		=> '$2a$10$O0fG6ExZRx4mEZxsRHqPKuDy9U2HW9M4UONC1hnsx84tW/bb5URFO',
	'Test 123'	=> '$2b$10$wOmSB/8mvcXJBAnPTJzO..tFOq4nCxP21vTfWqunrVi5Irsi3Obcy',
	'€U maffia'	=> '$2y$04$f5VgvyHCr0OiPbvjdZ8zJuPBHD6Tul6nleZSWUVkk/HSOKOC8DmFy',	# UTF-8!
);
my %tests_verify_bad = (
	'wrong password'	=> '$2a$10$O0fG6ExZRx4mEZxsRHqPKuDy9U2HW9M4UONC1hnsx84tW/bb5URFO',
	'garbage'			=> '0fG6ExZRx4mEZxsRHqPKuDy9U2HW9M4UONC1hnsx84tsdfs',
);
my @methods = map { $_, "password_$_"; } qw(
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

plan tests => scalar(@methods) + ($php ? 3 : 2) * (scalar(keys(%tests_verify_good)) + scalar(keys(%tests_verify_bad)));
my $class = 'PHP::Functions::Password';
foreach my $method (@methods) {
	can_ok($class, $method);
	if ($method =~ /^password/) {
		$class->import($method);
	}
}

foreach my $password (sort keys %tests_verify_good) {
	my $crypted = $tests_verify_good{$password};

	my $result = $class->verify($password, $crypted);
	ok($result, "Expect success from $class->verify(\"$password\", \"$crypted\")");

	$result = password_verify($password, $crypted);
	ok($result, "Expect success from password_verify(\"$password\", \"$crypted\")");

	if ($php) {
		my $phpcode = "var_export(password_verify('" . $password . "', '" . $crypted . "'));";
		my $h;
		open($h, '-|', $php, '-r', $phpcode) || die("Failed to execute $php: $!");
		my $line = <$h>;
		close($h);
		ok($line eq 'true', "Expect true from PHP's password_verify(\"$password\", \"$crypted\")");
	}
}
foreach my $password (sort keys %tests_verify_bad) {
	my $crypted = $tests_verify_bad{$password};

	my $result = $class->verify($password, $crypted);
	ok(!$result, "Expect failure from $class->verify(\"$password\", \"$crypted\")");

	$result = password_verify($password, $crypted);
	ok(!$result, "Expect failure from password_verify(\"$password\", \"$crypted\")");

	if ($php) {
		my $phpcode = "var_export(password_verify('" . $password . "', '" . $crypted . "'));";
		my $h;
		open($h, '-|', $php, '-r', $phpcode) || die("Failed to execute $php: $!");
		my $line = <$h>;
		close($h);
		ok($line eq 'false', "Expect false from PHP's password_verify(\"$password\", \"$crypted\")");
	}
}
