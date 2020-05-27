# This file must be saved in UTF-8 encoding!
use strict;
use warnings;
use Test::More;
use lib qw(../lib);


my %tests_verify_good = (
	'hello'			=> '$2a$10$O0fG6ExZRx4mEZxsRHqPKuDy9U2HW9M4UONC1hnsx84tW/bb5URFO',
	'Test 123'		=> '$2b$10$wOmSB/8mvcXJBAnPTJzO..tFOq4nCxP21vTfWqunrVi5Irsi3Obcy',
	'€U maffia'		=> '$2y$04$f5VgvyHCr0OiPbvjdZ8zJuPBHD6Tul6nleZSWUVkk/HSOKOC8DmFy',	# UTF-8!
);
if ($INC{'Crypt/Argon2.pm'} || eval { require Crypt::Argon2; }) {
	$tests_verify_good{'€uro 123'}   = '$argon2id$v=19$m=65536,t=4,p=1$d0pJRy83QmFtbjRoMTRMLg$LUUfxwFcaIeV/V/L6vs2ist/n41kUfuGEKKfoYFbOtY';	# UTF-8!
	$tests_verify_good{'top secret'} = '$argon2i$v=19$m=65536,t=4,p=1$QVVILkUvbUFaNGQzOEpKTA$PuQa7RB6cJWHFRJXGxXqi0qW51N801ZS9ZE7f+gDnjI';
}
else {
	diag('Skipping some tests because the Crypt::Argon2 module is not installed');
}
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
			#if ($1 < 5.5) {
			if ($1 < 7.3) {
				undef($php);
			}
		}
		diag("Found PHP executable $php with version $phpversion: " . ($php ? 'OK' : 'TOO OLD') . "\n");
	}
	else {
		undef($php);
	}
}

plan tests => 1 + scalar(@methods) + ($php ? 3 : 2) * (scalar(keys(%tests_verify_good)) + scalar(keys(%tests_verify_bad)));

my $class = 'PHP::Functions::Password';
use_ok($class) || BAIL_OUT("Failed to use $class");

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
