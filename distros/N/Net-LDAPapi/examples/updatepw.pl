#!/usr/bin/perl
#
#
#  updatepw.pl - Synchronize Passwords from Unix to LDAP
#  Author:  Clayton Donley, Motorola, <donley@cig.mot.com>
#
#  Reads in a password file, checks for existing entries matching
#  username@domain.com in the mail attribute and populates the CRYPTed
#  password from Unix into the userPassword attribute for that DN.
#
#  Usage:  updatepw.pl username username ... username
#  Example:  updatepw.pl "donley"
#

use Net::LDAPapi;

#  Define these values

$ldap_server = "localhost";
$PWFILE = "/etc/passwd";
$BASEDN = "o=Org, c=US";
$ROOTDN = "cn=Directory Manager, o=Org, c=US";
$ROOTPW = "abc123";
$MAILATTR = "mail";
$MYDOMAIN = "mycompany.com";

open(PASSWD,$PWFILE);
while($line = <PASSWD>)
{
   chop $line;

   ($user,$pass) = split(/:/,$line);
   $pwuser{$user} = $pass;
}
close(PASSWD);

#  Initialize Connection to LDAP Server

if (($ld = new Net::LDAPapi($ldap_server)) == -1)
{
   die "Cannot Open Connection to Server!";
}

#  Bind as the ROOT DIRECTORY USER to LDAP connection $ld

if ($ld->bind_s($ROOTDN,$ROOTPW) != LDAP_SUCCESS)
{
   die $ld->errstring;
}


#  Specify what to Search For

foreach $username (@ARGV)
{

#  Perform Search
   $filter = "($MAILATTR=$username\@$MYDOMAIN)";
   if ($ld->search_s($BASEDN,LDAP_SCOPE_SUBTREE,$filter,["uid","userpassword","mail"],0)
       != LDAP_SUCCESS)
   {
      $ld->unbind;
      die $ld->errstring;
   }

#  Here we get a HASH of HASHes... All entries, keyed by DN and ATTRIBUTE.
#
#  Since a reference is returned, we simply make %record contain the HASH
#  that the reference points to.

   if ($ld->first_entry == 0)
   {
      print "Not Found: $username\@$MYDOMAIN\n";
   } else {
      $dn = $ld->get_dn;
      @pass = $ld->get_values('userpassword');
      if ($pass[0] ne "{CRYPT}$pwuser{$username}")
      {
         $modifyrec{"userpassword"} = [ "{CRYPT}$pwuser{$username}" ];
         if ($ld->modify_s($dn,\%modifyrec) != LDAP_SUCCESS)
         {
            print "Error: $dn Unsuccessful.\n";
            print "modify_s: $ld->errstring\n";
         }
         print "Updated: $username\@$MYDOMAIN\n";
      } else {
         print "Matched: $username\@$MYDOMAIN\n";
      }
   }
}

$ld->unbind;

exit;

