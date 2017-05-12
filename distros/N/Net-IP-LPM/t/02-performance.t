# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-IP-LPM.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Net::IP::LPM') };

#use Socket qw( AF_INET );
#use Socket6 qw( inet_ntop inet_pton AF_INET6 );
use if $] <  5.014000, Socket  => qw(inet_aton AF_INET);
use if $] <  5.014000, Socket6 => qw(inet_ntop inet_pton AF_INET6);
use if $] >= 5.014000, Socket  => qw(inet_ntop inet_pton inet_aton AF_INET6 AF_INET);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# test speed 
my $cnt = 9000000;

my $lpm2 = Net::IP::LPM->new();

isa_ok($lpm2, 'Net::IP::LPM', 'Constructor');

diag "";
diag "Testing performance on full Internet BGP tables";

# load database from text file
open F1, "< t/asns.txt";
my $prefixes = 0;
my $t1 = time();
while (<F1>) {
	chomp;
	my ($prefix, $as) = split(/ /);
	$lpm2->add($prefix, $as);
	$prefixes++;
}
$lpm2->rebuild();
my $t2 = time() - $t1;

diag sprintf "loaded $prefixes prefixes in %d secs", $t2;

$t1 = time();
for (my $x = 0; $x < $cnt; $x++ ) {
	my $a = $x % 250; 	
	my $addr = "$a.10.$a.20";
	my $val = $lpm2->lookup($addr);
}

$t2 = time() - $t1;
diag sprintf "SPEED: %d lookups in %d secs, %.2f lookups/s", $cnt, $t2, $cnt/$t2;

# test speed  - raw
$t1 = time();
for (my $x = 0; $x < $cnt; $x++ ) {
	my $val = $lpm2->lookup_raw($x * $x);
}

$t2 = time() - $t1;
diag sprintf "SPEED: %d raw lookups in %d secs, %.2f lookups/s", $cnt, $t2, $cnt/$t2;


my $info = $lpm2->info();
diag "Trie info:";
foreach ( sort keys %{$info} ) {
	diag sprintf "   %s -> %s", $_, $info->{$_};
}


