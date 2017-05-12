#!/usr/bin/perl -w
#
#  testwalk.pl - Walks through Records Matching a Given Filter
#  Author:  Clayton Donley, Motorola, <donley@cig.mot.com>
#
#  Demonstration of OO Style LDAP Calls Using Net::LDAPapi
#
#  Similar to ldapwalk2.pl, only it uses the OO versions of the synchronous
#  functions to retrieve a hash containing the matching entries.
#
#  Usage:  testwalk.pl FILTER
#  Example:  testwalk.pl "sn=Donley"
#

use strict;
use Net::LDAPapi;

#  Define these values

my $ldap_server = "localhost";
my $BASEDN = "o=Org, c=US";
my $sizelimit = 100;            # Set to Maximum Number of Entries to Return
                                # Can set small to test error routines

#  Various Variable Declarations
my $ldcon;
my $ld;
my $filter;
my $result;
my %record;
my $dn;
my $item;
my $attr;

#  Initialize Connection to LDAP Server

if (($ldcon = new Net::LDAPapi($ldap_server)) == -1)
{
   die "Unable to initialize!";
}

if ($ldcon->bind_s != LDAP_SUCCESS)
{
   die $ldcon->errstring;
}

$ldcon->set_option(LDAP_OPT_SIZELIMIT,$sizelimit);

$ldcon->set_rebind_proc(\&rebindproc);

#  Specify what to Search For

$filter = $ARGV[0];

#  Perform Search

if ($ldcon->search_s($BASEDN,LDAP_SCOPE_SUBTREE,$filter,[],0) != LDAP_SUCCESS)
{
   print $ldcon->errstring . "\n";
   die;
}

#  Here we get a HASH of HASHes... All entries, keyed by DN and ATTRIBUTE.
#
#  Since a reference is returned, we simply make %record contain the HASH
#  that the reference points to.

%record = %{$ldcon->get_all_entries};

$ldcon->unbind;

# We can sort our resulting DNs quite easily...
my @dns = (sort keys %record);

# Print the number of entries returned.
print $#dns+1 . " entries returned.\n";

foreach $dn (@dns)
{
   print "dn: $dn\n";
   foreach $attr (keys %{$record{$dn}})
   {
      for $item ( @{$record{$dn}{$attr}})
      {
	 if ($attr =~ /binary/)
	 {
	    print "$attr: binary - length=" . length($item) . "\n";
	 }
	 elsif ($attr eq "jpegphoto")
         {
#
#  Notice how easy it is to take a binary attribute and dump it to a file
#  or such.  Gotta love PERL.
#
	    print "$attr: binary - length=" . length($item). "\n";
	    open (TEST,">$dn.jpg");
	    print TEST $item;
	    close (TEST);
         } else {
            print "$attr: $item\n";
         }
      }
   }
}

exit;

sub rebindproc
{

   return("","",LDAP_AUTH_SIMPLE);
}

