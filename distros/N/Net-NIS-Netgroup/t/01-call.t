#!/usr/bin/perl -w

use Test::More tests => 8;

use Net::NIS::Netgroup;

my $dom;
$dom = getdomainname();
ok ( defined($dom), "Successfully fetched domainname " . $dom );


SKIP: {
	skip 'Setting domain name only possible as root.', 3 if ($> != 0);
	my $newdom = "foobar";

	ok ( setdomainname($newdom), "Successfully set new domainname " . $newdom);

	is ( getdomainname(), $newdom, "Second get is equal to what I set ($newdom)" );

	ok ( setdomainname($dom), "Successfully set original domainname " . $dom);
}


#my $netgroup = undef;
my $netgroup = 'Users.users';
my $host = undef;
my $user = undef;
my $domain = undef;

SKIP: {
	#
	# Modify this "if" clause and the "netgroup" for testing on your
	# platform/system
	#
	skip 'Net group Users.users not known to exist on this platform', 2 if (! -f '/etc/productversion');
	ok ( innetgr($netgroup, $host, $user, $domain), "undef host/user/domain is \"innetgr\" \"$netgroup\"" );

	ok(scalar(listnetgr($netgroup)) > 0, "Net group \"$netgroup\" has some member(s)");
}
$netgroup = 'doesnotexist'; $host = 'nowherehost.local'; $user = 'barf'; $domain = 'surely.not.here.local';
ok ( !innetgr($netgroup, $host, $user, $domain), 'invalid netgroup/host/user/domain are not "innetgr"');

is(scalar(my @list = listnetgr($netgroup, 1)), 0, 'invalid netgroup/host/user/domain has an empty net group list');

1;
