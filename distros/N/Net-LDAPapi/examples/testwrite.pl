#!/usr/bin/perl -w
#
#  testwrite.pl - Test of LDAP Modify Operations in Perl5
#  Author:  Clayton Donley <donley@cig.mot.com>
#
#  This utility is mostly to demonstrate all the write operations
#  that can be done with LDAP through this PERL5 module.
#


use strict;
use Net::LDAPapi;


# This is the entry we will be adding.  Do not use a pre-existing entry.
my $ENTRYDN = "cn=New Guy, o=Org, c=US";

# This is the DN and password for an Administrator
my $ROOTDN = "cn=root, o=Org, c=US";
my $ROOTPW = "abc123";

my $ldap_server = "localhost";

my $ld = new Net::LDAPapi($ldap_server);

if ($ld == -1)
{
   die "Connection to LDAP Server Failed";
}

if ($ld->bind_s($ROOTDN,$ROOTPW) != LDAP_SUCCESS)
{
   die $ld->errstring;
}

my %testwrite = (
	"cn" => "Test User",
	"sn" => "User",
        "givenName" => "Test",
	"telephoneNumber" => "8475551212",
	"objectClass" => ["top","person","organizationalPerson",
           "inetOrgPerson"],
        "mail" => "tuser\@my.org",
);

if ($ld->add_s($ENTRYDN,\%testwrite) != LDAP_SUCCESS)
{
   die $ld->errstring;
}

print "Entry Added.\n";


%testwrite = (
	"telephoneNumber" => "7085551212",
        "mail" => {"a",["Test_User\@my.org"]},
);

if ($ld->modify_s($ENTRYDN,\%testwrite) != LDAP_SUCCESS)
{
   die $ld->errstring;
}

print "Entry Modified.\n";

exit;
#
# Delete the entry for $ENTRYDN
#
if ($ld->delete_s($ENTRYDN) != LDAP_SUCCESS)
{
   die $ld->errstring;
}

print "Entry Deleted.\n";

# Unbind to LDAP server
$ld->unbind;

exit;
