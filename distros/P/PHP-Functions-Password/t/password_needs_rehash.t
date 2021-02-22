# This file must be saved in UTF-8 encoding!
use strict;
use warnings;
use Test::More;
use lib qw(../lib);

my @tests = (
	{
		'crypted'	=> '$2a$10$O0fG6ExZRx4mEZxsRHqPKuDy9U2HW9M4UONC1hnsx84tW/bb5URFO',
		'algo'		=> 1, #$class::PASSWORD_BCRYPT,
		'options'	=> {},
		'expect'	=> 1,
		'reason'	=> 'algorithm signature is old',
	},
	{
		'crypted'	=> '$2b$10$wOmSB/8mvcXJBAnPTJzO..tFOq4nCxP21vTfWqunrVi5Irsi3Obcy',
		'algo'		=> 1, #$class::PASSWORD_BCRYPT,
		'options'	=> {
			'cost'	=> 10,
			'salt'	=> 'wOmSB/8mvcXJBAnPTJzO..',
		},
		'expect'	=> 1,
		'reason'	=> 'algorithm signature is old',
	},
	{
		'crypted'	=> '$2y$04$f5VgvyHCr0OiPbvjdZ8zJuPBHD6Tul6nleZSWUVkk/HSOKOC8DmFy',
		'algo'		=> 1, #$class::PASSWORD_BCRYPT,
		'options'	=> {
			'cost'	=> 4,
		},
		'expect'	=> 0,
		'reason'	=> 'up to date',
	},
	{
		'crypted'	=> '$2y$04$f5VgvyHCr0OiPbvjdZ8zJuPBHD6Tul6nleZSWUVkk/HSOKOC8DmFy',
		'algo'		=> 1, #$class::PASSWORD_BCRYPT,
		'options'	=> {
		},
		'expect'	=> 1,
		'reason'	=> 'cost is not the default (10)',
	},
	{
		'crypted'	=> '$2y$10$wOmSB/8mvcXJBAnPTJzO..tFOq4nCxP21vTfWqunrVi5Irsi3Obcy',
		'algo'		=> 1, #$class::PASSWORD_BCRYPT,
		'options'	=> {
			'cost'	=> 5,
		},
		'expect'	=> 1,
		'reason'	=> 'cost changed',
	},
	{
		'crypted'	=> '$2y$10$wOmSB/8mvcXJBAnPTJzO..tFOq4nCxP21vTfWqunrVi5Irsi3Obcy',
		'algo'		=> 1, #$class::PASSWORD_BCRYPT,
		'options'	=> {
			'salt'	=> 'f5VgvyHCr0OiPbvjdZ8zJu',
		},
		'expect'	=> 0,
		'reason'	=> 'salt options are ignored',
	},
	{
		'crypted'	=> 'yabadabadoo',	# completely invalid crypt string
		'algo'		=> 0,
		'options'	=> {},
		'expect'	=> 0,
		'reason'	=> 'unknown algorithm given',
	},
	{
		'crypted'	=> 'yabadabadoo',	# completely invalid crypt string
		'algo'		=> 1,
		'options'	=> {},
		'expect'	=> 1,	# invalid crypted strings should be rehashed
		'expect_php'=> 1,	# even though PHP say's no.
		'reason'	=> 'invalid crypt string',
	},

	{
		'crypted'	=> '$argon2id$v=19$m=65536,t=4,p=1$ZExWOUovRW1YNldkNFNsZA$2VI1DHxtqj3gQgVC5M3SZnYXZD4rM1mJR9666QVGCkQ',
		'algo'		=> 3, #$class::PASSWORD_ARGON2ID
		'options'	=> {
			'memory_cost'	=> 65536,
			'time_cost'		=> 4,
			'threads'		=> 1,
		},
		'expect'	=> 0,
		'reason'	=> 'up to date',
	},
	{
		'crypted'	=> '$argon2id$v=19$m=65536,t=4,p=1$ZExWOUovRW1YNldkNFNsZA$2VI1DHxtqj3gQgVC5M3SZnYXZD4rM1mJR9666QVGCkQ',
		'algo'		=> 3, #$class::PASSWORD_ARGON2ID
		'options'	=> {
			'memory_cost'	=> 65536,
			'time_cost'		=> 8,
			'threads'		=> 1,
		},
		'expect'	=> 1,
		'reason'	=> 'time_cost mismatch',
	},
	{
		'crypted'	=> '$argon2id$v=19$m=65536,t=4,p=1$ZExWOUovRW1YNldkNFNsZA$2VI1DHxtqj3gQgVC5M3SZnYXZD4rM1mJR9666QVGCkQ',
		'algo'		=> 3, #$class::PASSWORD_ARGON2ID
		'options'	=> {
			'memory_cost'	=> 123,
			'time_cost'		=> 4,
			'threads'		=> 1,
		},
		'expect'	=> 1,
		'reason'	=> 'memory_cost mismatch',
	},
	{
		'crypted'	=> '$argon2id$v=19$m=65536,t=4,p=1$ZExWOUovRW1YNldkNFNsZA$2VI1DHxtqj3gQgVC5M3SZnYXZD4rM1mJR9666QVGCkQ',
		'algo'		=> 3, #$class::PASSWORD_ARGON2ID
		'options'	=> {
			'memory_cost'	=> 65536,
			'time_cost'		=> 4,
			'threads'		=> 2,
		},
		'expect'	=> 1,
		'reason'	=> 'threads mismatch',
	},
);

my @methods = map { $_, "password_$_"; } qw(
	needs_rehash
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

plan tests => 1 + scalar(@methods) + ($php ? 3 : 2) * scalar(@tests);

my $class = 'PHP::Functions::Password';
use_ok($class) || BAIL_OUT("Failed to use $class");

foreach my $method (@methods) {
	can_ok($class, $method);
	if ($method =~ /^password/) {
		$class->import($method);
	}
}

foreach my $test (@tests) {
	my $crypted = $test->{'crypted'};
	my $algo	= $test->{'algo'};
	my $options	= $test->{'options'};
	my $expect	= $test->{'expect'};
	my $reason	= $test->{'reason'};

	my $result = $class->needs_rehash($crypted, $algo, $options);
	is($result, $expect, "Expect $expect from $class->needs_rehash(\"$crypted\",...) because $reason");

	$result = password_needs_rehash($crypted, $algo, $options);
	is($result, $expect, "Expect $expect from password_needs_rehash(\"$crypted\",...) because $reason");

	if ($php) {
		my $phpcode = "password_needs_rehash('" . $crypted . "', $algo, array(";
		if (defined($options->{'salt'})) {
			$phpcode .= "'salt'=>'" . $options->{'salt'} . "',";
		}
		if ($algo == 1) {
			if (defined($options->{'cost'})) {
				$phpcode .= "'cost'=>" . $options->{'cost'} . ",";
			}
		}
		elsif (($algo == 2) || ($algo == 3)) {
			if (defined($options->{'memory_cost'})) {
				$phpcode .= "'memory_cost'=>" . $options->{'memory_cost'} . ",";
			}
			if (defined($options->{'time_cost'})) {
				$phpcode .= "'time_cost'=>" . $options->{'time_cost'} . ",";
			}
			if (defined($options->{'threads'})) {
				$phpcode .= "'threads'=>" . $options->{'threads'} . ",";
			}
		}
		$phpcode .= "))";
		#print "$phpcode\n";
		my $h;
		open($h, '-|', $php, '-r', "var_export($phpcode);") || die("Failed to execute $php: $!");
		my $line = <$h>;
		close($h);
		my $result = $line eq 'true' ? 1 : 0;
		#print "$crypted\t$line\n";
		is($result, $expect, "Expect $expect from PHP's $phpcode because $reason");
		#print "\n\n";
	}
}

#diag('-----');
#use Crypt::Argon2;
#diag('Crypt::Argon2::VERSION: ' . $Crypt::Argon2::VERSION);
