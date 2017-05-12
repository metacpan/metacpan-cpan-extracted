# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RULI.t'

#########################

use Test::More tests => 12;
BEGIN { use_ok('Net::RULI'); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub dump_srv_list {
    my ($query, $srv_list_ref) = @_;

    diag("$query\n");

    foreach (@$srv_list_ref) {
	my $target = $_->{target};
	my $priority = $_->{priority};
	my $weight = $_->{weight};
	my $port = $_->{port};
	my $addr_list_ref = $_->{addr_list};
	
	diag("  target=$target priority=$priority weight=$weight port=$port addresses=");
	foreach (@$addr_list_ref) {
	    diag("$_ ");
	}
	diag("\n");
    }
}

ok(!defined(Net::RULI::ruli_sync_query('xxx', 'xxx', -1, 0)));

my $service = "_http._tcp";
my $domain = "bocaaberta.com.br";
my $srv_list_ref = Net::RULI::ruli_sync_query($service, $domain, 
					 -1, 0);
ok(defined($srv_list_ref));
ok(ref($srv_list_ref));
&dump_srv_list("ruli_sync_query: service=$service domain=$domain\n", 
	       $srv_list_ref);

$service = "_http._tcp";
$domain = "uol.com.br";
$srv_list_ref = Net::RULI::ruli_sync_query($service, $domain, 
				      -1, 0);
ok(defined($srv_list_ref));
ok(ref($srv_list_ref));
&dump_srv_list("ruli_sync_query: service=$service domain=$domain\n", 
	       $srv_list_ref);

$domain = "aol.com";
$srv_list_ref = Net::RULI::ruli_sync_smtp_query($domain, 0);
ok(defined($srv_list_ref));
ok(ref($srv_list_ref));
&dump_srv_list("ruli_sync_smtp_query: domain=$domain\n", 
	       $srv_list_ref);

$domain = "kensingtonlabs.com";
$srv_list_ref = Net::RULI::ruli_sync_smtp_query($domain, 0);
ok(defined($srv_list_ref));
ok(ref($srv_list_ref));
&dump_srv_list("ruli_sync_smtp_query: domain=$domain\n", 
	       $srv_list_ref);

$domain = "registro.br";
$srv_list_ref = Net::RULI::ruli_sync_http_query($domain, -1, 0);
ok(defined($srv_list_ref));
ok(ref($srv_list_ref));
&dump_srv_list("ruli_sync_http_query: domain=$domain\n",
               $srv_list_ref);

