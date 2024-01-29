use strict;
use warnings;
use Test::More;
use lib qw(../lib);

my %tests_info = (
	'$2a$10$O0fG6ExZRx4mEZxsRHqPKuDy9U2HW9M4UONC1hnsx84tW/bb5URFO' => {
		'algo'		=> 1, #$class::PASSWORD_BCRYPT,
		'algoName'	=> 'bcrypt',
		'options'	=> {
			'cost'	=> 10,
		},
		'algoSig'	=> '2a',
		'salt'		=> 'O0fG6ExZRx4mEZxsRHqPKu',
		'hash'		=> 'Dy9U2HW9M4UONC1hnsx84tW/bb5URFO',
	},
	'$2b$10$wOmSB/8mvcXJBAnPTJzO..tFOq4nCxP21vTfWqunrVi5Irsi3Obcy' => {
		'algo'		=> 1, #$class::PASSWORD_BCRYPT,
		'algoName' => 'bcrypt',
		'options'	=> {
			'cost'	=> 10,
		},
		'algoSig'	=> '2b',
		'salt'		=> 'wOmSB/8mvcXJBAnPTJzO..',
		'hash'		=> 'tFOq4nCxP21vTfWqunrVi5Irsi3Obcy',
	},
	'$2y$04$f5VgvyHCr0OiPbvjdZ8zJuPBHD6Tul6nleZSWUVkk/HSOKOC8DmFy' => {
		'algo'		=> 1, #$class::PASSWORD_BCRYPT,
		'algoName' => 'bcrypt',
		'options'	=> {
			'cost'	=> 4,
		},
		'algoSig'	=> '2y',
		'salt'		=> 'f5VgvyHCr0OiPbvjdZ8zJu',
		'hash'		=> 'PBHD6Tul6nleZSWUVkk/HSOKOC8DmFy',
	},
	'yabadabadoo' => {	# This is the expected result for password_get_info(). The get_info() method will return undef instead.
		'algo'		=> 0,
		'algoName'	=> 'unknown',
		'options'	=> {},
	},
	'$argon2id$v=19$m=65536,t=4,p=1$cUxuUXdZZWprZmVWT004eUNRejRVdQ$jBK/oG9+9hUdM55ImaE1WR/DsxSMfU4XJKU' => {
		'algo'		=> 3, #$class::PASSWORD_ARGON2ID,
		'algoName' => 'argon2id',
		'options'	=> {
			'memory_cost'	=> 65536,
			'time_cost'		=> 4,
			'threads'		=> 1,
		},
		'algoSig'	=> 'argon2id',
		'salt'		=> 'cUxuUXdZZWprZmVWT004eUNRejRVdQ',
		'hash'		=> 'jBK/oG9+9hUdM55ImaE1WR/DsxSMfU4XJKU',
		'version'	=> 19,
	},
);

my @methods = map { $_, "password_$_"; } qw(
	get_info
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
	eval {
		require	JSON::PP;
	};
	if ($@) {
		note("JSON::PP not avaible. Won't use PHP\n");
		undef($php);
	}
}

plan tests => 1 + scalar(@methods) + ($php ? 3 : 2) * scalar(keys(%tests_info));

my $class = 'PHP::Functions::Password';
use_ok($class) || BAIL_OUT("Failed to use $class");

foreach my $method (@methods) {
	can_ok($class, $method);
	if ($method =~ /^password/) {
		$class->import($method);
	}
}

foreach my $crypted (sort keys %tests_info) {
	my $expect = $tests_info{$crypted};

	my $info = $class->get_info($crypted);
	#note(JSON::PP::encode_json($info));
	is_deeply($info, $expect->{'algo'} eq 0 ? undef : $expect, "$class->get_info(\"$crypted\")");

	$info = password_get_info($crypted);
	#note(JSON::PP::encode_json($info));
	is_deeply($info, $expect, "password_get_info(\"$crypted\")");

	if ($php) {
		$crypted =~ s/^\$2[ab]\$/\$2y\$/;	# because PHP's function doesn't recognize older bcrypt signatures
		my $phpcode = "print json_encode(password_get_info('" . $crypted . "'),JSON_FORCE_OBJECT);";
		my $h;
		open($h, '-|', $php, '-r', $phpcode) || die("Failed to execute $php: $!");
		my $json = join('', <$h>);
		close($h);
		$info = JSON::PP::decode_json($json);
		delete($expect->{'algoSig'});
		delete($expect->{'salt'});
		delete($expect->{'hash'});
		delete($expect->{'version'});
		#note("$json\n");
		is_deeply($info, $expect, "PHP's password_get_info(\"$crypted\") matches ours");
	}


}
