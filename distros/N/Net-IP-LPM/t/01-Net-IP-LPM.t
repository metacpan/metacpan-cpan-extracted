# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-IP-LPM.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

open(STDOUT, ">&STDERR");

use Test::More tests => 13;
use Data::Dumper;
BEGIN { use_ok('Net::IP::LPM') };

#use Socket qw( AF_INET );
#use Socket6 qw( inet_ntop inet_pton AF_INET6 );
use if $] <  5.014000, Socket  => qw(inet_aton AF_INET);
use if $] <  5.014000, Socket6 => qw(inet_ntop inet_pton AF_INET6);
use if $] >= 5.014000, Socket  => qw(inet_ntop inet_pton inet_aton AF_INET6 AF_INET);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $lpm = Net::IP::LPM->new();

isa_ok($lpm, 'Net::IP::LPM', 'Constructor');

# testo on empty database 
my $lpm_empty = Net::IP::LPM->new();

ok( !defined($lpm_empty->lookup('1.2.3.4')),  'lookup on empty DB' );
ok( !defined($lpm_empty->lookup('fe0::1')),  'lookup on empty DB' );

# list of prefixes to test
my @prefixes = ( 
		'0.0.0.0/0', 
		'147.229.3.1', '147.229.3.2/32', '147.229.3.0/24', '147.229.0.0/16',
		'10.255.3.0/24', '10.255.3.0/32',
		'224.0.0.0/4', '224.0.0.0/4',
		'224.0.0.0/5', '224.0.0.0/5',
		'::/0',
		'2001:67c:1220:f565::1234', '2001:67c:1220:f565::1235/128', 
		'2001:67c:1220:f565::/64', '2001:67c:1220::/32',
		'2001:67c:1220:f565::/64', '2001:67c:1220::/32',
		'2001:67c:1220:c000::/56', 
		'2001:67c:1220:c000::/52', 
		'ff3a::/32', 'ff3a::/32'
		);

foreach (@prefixes) {
	$lpm->add($_, $_);
}

#$lpm->rebuild();

my %tests = ( 
		'147.229.3.0'	=> '147.229.3.0/24',
		'147.229.3.1'	=> '147.229.3.1',
		'147.229.3.2'	=> '147.229.3.2/32',
		'147.229.3.3'	=> '147.229.3.0/24',
		'147.229.3.10'	=> '147.229.3.0/24',
		'147.229.3.254'	=> '147.229.3.0/24',
		'147.229.3.255'	=> '147.229.3.0/24',
		'147.229.4.0'	=> '147.229.0.0/16',
		'147.229.4.1'	=> '147.229.0.0/16',
		'147.228.255.255'	=> '0.0.0.0/0',
		'147.229.0.0'	=> '147.229.0.0/16',
		'147.229.255.255'	=> '147.229.0.0/16',
		'147.230.0.0'	=> '0.0.0.0/0',
		'147.230.0.1'	=> '0.0.0.0/0',
		'10.255.3.0'	=> '10.255.3.0/32',
		'0.0.0.0'		=> '0.0.0.0/0',
		'0.0.0.1'		=> '0.0.0.0/0',
		'255.255.255.254'	=> '0.0.0.0/0',
		'255.255.255.255'	=> '0.0.0.0/0',
		'2001:67c:1220::1'			=> '2001:67c:1220::/32',
		'2001:67c:1220:f565::1234'	=> '2001:67c:1220:f565::1234',
		'2001:67c:1220:f565::'		=> '2001:67c:1220:f565::/64',
		'2001:67c:1220:f565::1'		=> '2001:67c:1220:f565::/64',
		'2001:67c:1220:f565:FFFF:FFFF:FFFF:FFFF'	=> '2001:67c:1220:f565::/64',
		'2001:67c:1220:f566::'	=> '2001:67c:1220::/32',
		'2001:67c:1220:f566::1'	=> '2001:67c:1220::/32',
		'2001:67c:2325:f566::1'	=> '2001:67c:1220::/32',
		'2001:67b:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF'	=> '::/0',
		'2001:67d::1'			=> '::/0',
		'2001::1'				=> '::/0',
		'2001:67c:1220:c1b0:c57b:6ec4:6aee:4d7'		=> '2001:67c:1220:c000::/52',
		'2001:67c:1220:c0b0:c57b:6ec4:6aee:4d7'		=> '2001:67c:1220:c000::/56',
		'FFFF:FFFF:FFFF:FFF:FFFF:FFFF:FFFF:FFFF'	=> '::/0',
		'FFFF:FFFF:FFFF:FFF:FFFF:FFFF:FFFF:FFFE'	=> '::/0',
		'::0.0.0.0'	=> '::/0',
		'0001::'	=> '::/0',
		'2001::1'	=> '::/0',
		);

# std lookup
my %results = ();
#diag "\n";
while ( my ($a, $p) = each %tests ) {
	my $res = $lpm->lookup($a);
	if ($p ne $res) {
		diag sprintf "FAIL %s \t-> \t%s =%s %s\n", $a, $p, $p eq $res ? '=' : '!', $res;
	}
	$results{$a} = $res;
}

ok( eq_hash(\%tests, \%results), 'lookup' );

# std raw lookup
%results = ();
#diag "\n";
while ( my ($a, $p) = each %tests ) {
	my $ab ;
	if ($a =~ /:/) {
		$ab = inet_pton(AF_INET6, $a);
	} else {
		#$ab = inet_pton(AF_INET, $a);
		$ab = inet_aton($a);
	}
	my $res = $lpm->lookup_raw($ab);
	if ($p ne $res) {
		diag sprintf "FAIL RAW %s \t-> \t%s =%s %s\n", $a, $p, $p eq $res ? '=' : '!', $res;
	}
	$results{$a} = $res;
}

ok( eq_hash(\%tests, \%results), 'lookup_raw' );

# std cache raw lookup
%results = ();
#diag "\n";
while ( my ($a, $p) = each %tests ) {
	my $ab ;
	if ($a =~ /:/) {
		$ab = inet_pton(AF_INET6, $a);
	} else {
		#$ab = inet_pton(AF_INET, $a);
		$ab = inet_aton($a);
	}
	my $res = $lpm->lookup_cache_raw($ab);
	if ($p ne $res) {
		diag sprintf "FAIL CACHE RAW %s \t-> \t%s =%s %s\n", $a, $p, $p eq $res ? '=' : '!', $res;
	}
	$results{$a} = $res;
}

ok( eq_hash(\%tests, \%results), 'lookup_cache_raw' );

# check for retruning undef
my @prefixes2 = ( 
		'147.229.3.1', '147.229.3.2/32', '147.229.3.0/24', '147.229.0.0/16',
		'10.255.3.0/24', '10.255.3.0/32',
		'224.0.0.0/4', '224.0.0.0/4',
		'224.0.0.0/5', '224.0.0.0/5',
		'2001:67c:1220:f565::1234', '2001:67c:1220:f565::1235/128', 
		'2001:67c:1220:f565::/64', '2001:67c:1220::/32',
		'2001:67c:1220:f565::/64', '2001:67c:1220::/32',
		'2001:67c:1220:c000::/52', 
		'2001:67c:1220:c000::/56', 
		'ff3a::/32', 'ff3a::/32'
		);

my $lpm2 = Net::IP::LPM->new();
foreach (@prefixes2) {
	$lpm2->add($_, $_);
}

$lpm2->rebuild();

my %tests2 = ( 
		'147.229.3.0'	=> '147.229.3.0/24',
		'147.229.3.1'	=> '147.229.3.1',
		'147.229.3.2'	=> '147.229.3.2/32',
		'147.229.3.3'	=> '147.229.3.0/24',
		'147.229.3.10'	=> '147.229.3.0/24',
		'147.229.3.254'	=> '147.229.3.0/24',
		'147.229.3.255'	=> '147.229.3.0/24',
		'147.229.4.0'	=> '147.229.0.0/16',
		'147.229.4.1'	=> '147.229.0.0/16',
		'147.228.255.255'	=> undef,
		'147.229.0.0'	=> '147.229.0.0/16',
		'147.229.255.255'	=> '147.229.0.0/16',
		'147.230.0.0'	=> undef,
		'147.230.0.1'	=> undef,
		'10.255.3.0'	=> '10.255.3.0/32',
		'0.0.0.0'		=> undef,
		'0.0.0.1'		=> undef,
		'255.255.255.254'	=> undef,
		'255.255.255.255'	=> undef,
		'2001:67c:1220::1'			=> '2001:67c:1220::/32',
		'2001:67c:1220:f565::1234'	=> '2001:67c:1220:f565::1234',
		'2001:67c:1220:f565::'		=> '2001:67c:1220:f565::/64',
		'2001:67c:1220:f565::1'		=> '2001:67c:1220:f565::/64',
		'2001:67c:1220:f565:FFFF:FFFF:FFFF:FFFF'	=> '2001:67c:1220:f565::/64',
		'2001:67c:1220:f566::'	=> '2001:67c:1220::/32',
		'2001:67c:1220:f566::1'	=> '2001:67c:1220::/32',
		'2001:67c:2325:f566::1'	=> '2001:67c:1220::/32',
		'2001:67b:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF'	=> undef,
		'2001:67d::1'			=> undef,
		'2001::1'				=> undef,
		'2001:67c:1220:c1b0:c57b:6ec4:6aee:4d7'		=> '2001:67c:1220:c000::/52',
		'2001:67c:1220:c0b0:c57b:6ec4:6aee:4d7'		=> '2001:67c:1220:c000::/56',
		'FFFF:FFFF:FFFF:FFF:FFFF:FFFF:FFFF:FFFF'	=> undef,
		'FFFF:FFFF:FFFF:FFF:FFFF:FFFF:FFFF:FFFE'	=> undef,
		'::0.0.0.0'	=> undef,
		'0001::'	=> undef,
		'2001::1'	=> undef,
		);

# std lookup
my %results2 = ();
#diag "\n";
while ( my ($a, $p) = each %tests2 ) {
	my $res = $lpm2->lookup($a);
	$results2{$a} = $res;
	$p = "<undef>" if (!defined($p));
	$res = "<undef>" if (!defined($res));
	if ($p ne $res) {
		diag sprintf "FAIL %s \t-> \t%s =%s %s\n", $a, $p, $p eq $res ? '=' : '!', $res;
	}
}

ok( eq_hash(\%tests2, \%results2), 'lookup = undef' );

# std raw lookup
%results2 = ();
#diag "\n";
while ( my ($a, $p) = each %tests2 ) {
	my $ab ;
	if ($a =~ /:/) {
		$ab = inet_pton(AF_INET6, $a);
	} else {
		#$ab = inet_pton(AF_INET, $a);
		$ab = inet_aton($a);
	}
	my $res = $lpm2->lookup_raw($ab);
	$results2{$a} = $res;
	$p = "<undef>" if (!defined($p));
	$res = "<undef>" if (!defined($res));
	if ($p ne $res) {
		diag sprintf "FAIL RAW %s \t-> \t%s =%s %s\n", $a, $p, $p eq $res ? '=' : '!', $res;
	}
}

ok( eq_hash(\%tests2, \%results2), 'lookup_raw - undef' );

# std cache raw lookup
%results2 = ();
#diag "\n";
while ( my ($a, $p) = each %tests2 ) {
	my $ab ;
	if ($a =~ /:/) {
		$ab = inet_pton(AF_INET6, $a);
	} else {
		#$ab = inet_pton(AF_INET, $a);
		$ab = inet_aton($a);
	}
	my $res = $lpm2->lookup_cache_raw($ab);
	$results2{$a} = $res;
	$p = "<undef>" if (!defined($p));
	$res = "<undef>" if (!defined($res));
	if ($p ne $res) {
		diag sprintf "FAIL CACHE RAW %s \t-> \t%s =%s %s\n", $a, $p, $p eq $res ? '=' : '!', $res;
	}
}

ok( eq_hash(\%tests2, \%results2), 'lookup_cache_raw - undef' );


# DUMP - without default 
my $cnt = 0;
my $dump = $lpm2->dump();
foreach ( sort keys %{$dump} ) {
	if ($_ !~ /$dump->{$_}/ && $_ ne '2001:67c::/32') {
	    diag sprintf "   %s -> %s", $_, $dump->{$_};
		$cnt++;
	}
}

ok( $cnt == 0, 'dump()' );


# DUMP - with default 
$cnt = 0;
$lpm2->add('0.0.0.0/0', '0.0.0.0/0');
$dump = $lpm2->dump();
#diag Dumper($dump);
foreach ( sort keys %{$dump} ) {
	if ($_ !~ /$dump->{$_}/ && $_ ne '2001:67c::/32') {
	    diag sprintf "   %s -> %s", $_, $dump->{$_};
		$cnt++;
	}
}

ok( $cnt == 0, 'dump()' );

# DUMP - v4 only
$cnt = 0;
my $lpm3 = Net::IP::LPM->new();
$lpm3->add('0.0.0.0/0', '0.0.0.0/0');
$lpm3->add('147.229.0.0/16', '147.229.0.0/16');
$dump = $lpm3->dump();
#diag Dumper($dump);
foreach ( sort keys %{$dump} ) {
	if ($_ !~ /$dump->{$_}/ && $_ ne '2001:67c::/32') {
	    diag sprintf "   %s -> %s", $_, $dump->{$_};
		$cnt++;
	}
}

ok( $cnt == 0, 'dump()' );

