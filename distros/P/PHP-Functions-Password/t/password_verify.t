# This file must be saved in UTF-8 encoding!
use strict;
use warnings;
use Test::More;
use Test::More::UTF8;
use lib qw(../lib);
use utf8;	# i.e. strings declared in this file are in UTF-8 encoding

# Tell Perl what the terminal encoding is:
if (defined($ENV{'LANG'})) {
	if ($ENV{'LANG'} =~ /\bUTF-8\b/i) {
		binmode(STDOUT, ':utf8');
		binmode(STDERR, ':utf8');
		note("Terminal encoding is UTF-8.\n");
	}
	else {
		note("Terminal encoding is not UTF-8.\n");
	}
}
else {
	note("Unable to determine terminal encoding. Assuming UTF-8.\n");
	binmode(STDOUT, ':utf8');
	binmode(STDERR, ':utf8');
}


my %tests_verify_good = (
	'hello'			=> '$2a$10$O0fG6ExZRx4mEZxsRHqPKuDy9U2HW9M4UONC1hnsx84tW/bb5URFO',
	'Test 123'		=> '$2b$10$wOmSB/8mvcXJBAnPTJzO..tFOq4nCxP21vTfWqunrVi5Irsi3Obcy',
	'€U maffia'		=> '$2y$04$f5VgvyHCr0OiPbvjdZ8zJuPBHD6Tul6nleZSWUVkk/HSOKOC8DmFy',	# UTF-8!

	# These should all work with the same hash since the first 72 bytes in each are the same:
	'これは、それぞれが複数のバイトで構成される文字である日本語の文です。' => '$2y$10$8r90pAKtxZzcWQRsJpOKge6rXAP.1UtvQntdk38RhuAjrXXkplqr.',	# 34 chars, 102 bytes
	'これは、それぞれが複数のバイトで構成される文字であ'				=> '$2y$10$8r90pAKtxZzcWQRsJpOKge6rXAP.1UtvQntdk38RhuAjrXXkplqr.',	# 25 chars, 75 bytes
	'これは、それぞれが複数のバイトで構成される文字で'					=> '$2y$10$8r90pAKtxZzcWQRsJpOKge6rXAP.1UtvQntdk38RhuAjrXXkplqr.',	# 24 chars, 72 bytes

	# See is Perl treats mid character truncations the same as PHP:
	'*これは、それぞれが複数のバイトで構成される文字である日本語の文です。'=> '$2y$10$sTABy3KkqHfAFn804McWyOZ05GuCTJv/f2UftgDgt18FT1aLTWw5a',	# 35 chars, 104 bytes
	'*これは、それぞれが複数のバイトで構成される文字で'				=> '$2y$10$sTABy3KkqHfAFn804McWyOZ05GuCTJv/f2UftgDgt18FT1aLTWw5a',	# 25 chars, 73 bytes
	'*これは、それぞれが複数のバイトで構成される文字'					=> '$2y$10$d0zIWdmjJV4etRUhHmHRDeAL4OD6.i.omgK8.neAFVpqJxJiX/jTa',	# 24 chars, 70 bytes
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
	'wrong again'		=> '0fG6ExZRx4mEZxsRHqPKuDy9U2HW9M4UONC1hnsx84tsdfs',
	'bad guess'			=> '$2y$10$17ZzQQNFszjoSuWnSmYuH.OlgJz/sTyxWlYlmJPY/ASP/R0n/pNIq',
	'これは、それぞれが複数のバイトで構成される文字'	=> '$2y$10$8r90pAKtxZzcWQRsJpOKge6rXAP.1UtvQntdk38RhuAjrXXkplqr.',	# 23 chars, 69 bytes
	'*これは、それぞれが複数のバイトで構成される文字' => '$2y$10$sTABy3KkqHfAFn804McWyOZ05GuCTJv/f2UftgDgt18FT1aLTWw5a',	# 24 chars, 70 bytes
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
		my $too_old;
		if ($phpversion =~ /^(\d{1,3}\.\d{1,6})\b/) {
			#if ($1 < 5.5) {
			if ($1 < 7.3) {
				$too_old = 1;
			}
		}
		note("Found PHP executable $php with version $phpversion: " . ($too_old ? 'TOO OLD' : 'OK') . "\n");
		if ($too_old) {
			undef($php);
		}
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
	note("Testing good password: $password");

	my $result = $class->verify($password, $crypted);
	ok($result, "Expect success from $class->verify(\$password, \"$crypted\")");

	$result = password_verify($password, $crypted);
	ok($result, "Expect success from password_verify(\$password, \"$crypted\")");

	if ($php) {
		my $phpcode = "var_export(password_verify('" . $password . "', '" . $crypted . "'));";
		my $h;
		open($h, '-|', $php, '-r', $phpcode) || die("Failed to execute $php: $!");
		my $line = <$h>;
		close($h);
		ok($line eq 'true', "Expect true from PHP's password_verify(\$password, \"$crypted\")");
	}
	note('');
}
foreach my $password (sort keys %tests_verify_bad) {
	my $crypted = $tests_verify_bad{$password};
	note("Testing bad password: $password");

	my $result = $class->verify($password, $crypted);
	ok(!$result, "Expect failure from $class->verify(\$password, \"$crypted\")");

	$result = password_verify($password, $crypted);
	ok(!$result, "Expect failure from password_verify(\$password, \"$crypted\")");

	if ($php) {
		my $phpcode = "var_export(password_verify('" . $password . "', '" . $crypted . "'));";
		my $h;
		open($h, '-|', $php, '-r', $phpcode) || die("Failed to execute $php: $!");
		my $line = <$h>;
		close($h);
		ok($line eq 'false', "Expect false from PHP's password_verify(\$password, \"$crypted\")");
	}
	note('');
}
