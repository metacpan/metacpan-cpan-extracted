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


my @test_passwords = (
	'Random first name and birthday',
	'€U maffia',
	'これは、それぞれが複数のバイトで構成される文字である日本語の文です。',	# 34 chars, 102 bytes
	#'これは、それぞれが複数のバイトで構成される文字である日本語の文です。',	# 34 chars, 102 bytes
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

my $class = 'PHP::Functions::Password';
my $require_ok = eval "require $class";
$require_ok || BAIL_OUT("Failed to require $class");

plan tests => 1 + scalar(@methods) + ($php ? 6 : 5) * scalar(@test_passwords) * scalar($class->algos());

require_ok($class) || BAIL_OUT("Failed to require $class");

foreach my $method (@methods) {
	can_ok($class, $method);
	if ($method =~ /^password/) {
		$class->import($method);
	}
}

my %alias_to_algo = (
	'bcrypt(2y)' => $class->PASSWORD_BCRYPT,
);

if ($INC{'Crypt/Argon2.pm'} || eval { require Crypt::Argon2; }) {
	$alias_to_algo{'argon2i'}  = $class->PASSWORD_ARGON2I;
	$alias_to_algo{'argon2id'} = $class->PASSWORD_ARGON2ID;
}
else {
	diag('Skipping some tests because the Crypt::Argon2 module is not installed');
}

note('');
foreach my $password (@test_passwords) {
	foreach my $sig (sort keys %alias_to_algo) {
		my $algo = $alias_to_algo{$sig};
		note("Testing $sig using \$password = '$password';");
		my $crypted = eval {
			$class->hash($password, 'algo' => $algo);
		};
		ok(!$@, "$class->hash(\$password, 'algo' => $algo) does not die");
		if ($@) {
			diag($@);
		}
		else {
			ok(length($crypted) >= 60, "$class->hash(\$password, 'algo' => $algo) returns a crypted string");
			#note("length $sig: " . length($crypted));
			if (1) {
				my $result = eval {
					$class->verify($password, $crypted);
				};
				ok(!$@, "$class->verify(\$password, '$crypted') does not die");
				if ($@) {
					diag($@);
				}
				else {
					ok($result, "Expect success from verify method using password and new crypted string \"$crypted\"");
					$result = password_verify($password, $crypted);
					ok($result, "Expect success from password_verify function using password and new crypted string \"$crypted\"");
				}
			}
			if ($php) {
				my $phpcode = "var_export(password_verify('" . $password . "', '" . $crypted . "'));";
				my $h;
				open($h, '-|', $php, '-r', $phpcode) || die("Failed to execute $php: $!");
				my $line = <$h>;
				close($h);
				ok($line eq 'true', "Expect true from PHP's password_verify(\$password, '$crypted')");
			}
		}
		note('');
	}
}


unless ($ENV{'HARNESS_ACTIVE'}) {
	foreach my $password (@test_passwords) {
		#print password_hash($password, $class->PASSWORD_ARGON2ID, 'tag_length' => 16) . "\n";
		#print password_hash($password, $class->PASSWORD_ARGON2ID) . "\n";
		#print password_hash($password, $class->PASSWORD_BCRYPT) . "\n";
		last;
	}

	if ('pepper demonstration') {
		note('Demonstrating pepper use:');
		eval {
			require Digest::SHA;
		};
		if ($@) {
			note("Digest::SHA not available, so peppering can't be demonstrated");
		}
		else {
			Digest::SHA->import('hmac_sha256');
			my $password = 'Random childs firstname and birthday';
			note("password: $password");
			my $pepper = 'Abracadabra and Hocus pocus';  # retrieve this from a secrets config file for example (and don't loose it!)
			note("pepper: $pepper");
			my $peppered_password = hmac_sha256($password, $pepper);
			note('peppered password (in hex for viewing): ' .  unpack('H*', $peppered_password));
			my $crypted_string = password_hash($password);  # store this in your database
			note("hash: $crypted_string");
		}
	}

}
