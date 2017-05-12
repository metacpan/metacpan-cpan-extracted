#! /usr/bin/perl -w
#
# ldap_mod_attr - change an attribute in someone's LDAP entry
#
# Author: Andrew J Cosgriff <ajc@bing.wattle.id.au>
# Created: Thu Dec  4 19:48:03 1997
# Version: $Id: ldap_mod_attr.pl,v 1.1.1.1 1998/01/30 19:10:06 jonl Exp $
# Keywords: ldap modify add remove attribute commmand-line useful really
#
########################################
#
### Commentary:
#
# Sick of typing in lines of ldapmodify stuff just to change one or
# two attributes ?  This is for you...
#
### TO DO:
#
# - take note when dealing with multiple values for an attribute
#
########################################
#
### Code:
#
use Net::LDAPapi;
use Getopt::Std;
use File::Basename;
my $version = substr q$Revision: 1.1.1.1 $, 10;
chop $version;
##########
#
# Defaults
#
$ldap_server = "ldap.org.au";
$BASEDN = $ENV{'LDAP_BASEDN'} || "o=Org, c=AU";
$ROOTDN = "cn=admin, o=Org, c=AU";
$ROOTPW = "";
$batchmode = 0;
$verbosemode = 0;
$modify_all = 0;
$do_nothing = 0;
$UIDATTR = "uid";
#
# Parse command line options, explained here :
#
$usage_msg = "ldap_mod_attr version " . $version . " by Andrew J Cosgriff <ajc\@bing.wattle.id.au>
Usage : " . basename($0) . " [options] <search filter> <attr=value> <attr=value> ...

[options] being one or more of :
-a        : modify all matching entries (rather than prompting for one)
-b <dn>   : base DN for searches
            [ default - $BASEDN ]
-D <dn>   : bind as this DN to do the modifications
            [ default - $ROOTDN ]
-h <host> : ldap server to talk to
            [ default - $ldap_server ]
-n        : do nothing, just show what would happen (implies -v)
-q        : batch/quiet mode - no prompting for password
                             - no prompting if there are multiple matches
-v        : verbose mode - print \"<attr> changed from <old> to <new>\"
-w <pwd>  : the password for the DN we bind as with -D

<search filter> being either :
- a uid, eg. \"nate\"
- an RFC 1558-style LDAP search filter, eg. \"cn=Nathan Bailey\"

exitcodes are :
1 - general error
2 - no matches returned by ldap_search_s
3 - too many matches (for -q)
";

if (getopts('ab:D:h:nqvw:?', \%opt) == 0) {
  print $usage_msg;
  exit 1;
}

$modify_all = 1 if (defined $opt{'a'});
$BASEDN = $opt{'b'} if (defined $opt{'b'});
$ROOTDN = $opt{'D'} if (defined $opt{'D'});
$ldap_server = $opt{'h'} if (defined $opt{'h'});
$batchmode = 1 if (defined $opt{'q'});
$verbosemode = 1 if (defined $opt{'v'});
$do_nothing = 1 if (defined $opt{'n'});
$verbosemode = $do_nothing || $verbosemode;
$ROOTPW = $opt{'w'} if (defined $opt{'w'});
#
# Print help if they want/need it
#
if ($opt{'?'}) {
  print $usage_msg;
  exit 1;
}

if ($#ARGV == -1) {
  print "Need to specify a search filter and attr=value pairs\n";
  print $usage_msg;
  exit 1;
}

if ($#ARGV <= 0) {
  print "Need to specify attr=value pairs as well\n";
  print $usage_msg;
  exit 1;
}

print "Well hey, we\'re in DoNothing mode...\n" if $do_nothing;
#
# Ask for the Root DN's password if they didn't specify it
#
if ($ROOTPW eq "") {
  print "Attempting to bind as $ROOTDN\nPassword : ";
  system "stty -echo";
  $ROOTPW = <STDIN>;
  chomp $ROOTPW;
  system "stty echo";
  print "\n";
}
#
# Initialize Connection to LDAP Server
#
if (($ld = ldap_open($ldap_server,LDAP_PORT)) eq "")
{
  die "ldap_init failed";
}
#
# Bind as the specified DN
#
if ((ldap_simple_bind_s($ld,$ROOTDN,$ROOTPW)) != LDAP_SUCCESS)
{
  ldap_perror($ld,"ldap_simple_bind_s");
  die "Failed to bind as $ROOTDN";
}
#
# Perform search
#
$filter = shift @ARGV;

if ($filter !~ /[\(\)\&\|=]/) {
  $filter = "($UIDATTR=$filter)";
}
print "\nSearching for $filter\n" if ($verbosemode);
@attrs = ();
if (ldap_search_s($ld,$BASEDN,LDAP_SCOPE_SUBTREE,$filter,\@attrs,0,$result)
    != LDAP_SUCCESS)
  {
    $err = ldap_get_lderrno($ld,$errdn,$extramsg);
    print &ldap_err2string($err),"\n";
                print "DN $errdn\n" if defined $errdn;
    print "extramsg $extramsg\n" if defined $extramsg;
  
    ldap_unbind($ld);
    die "Search for $filter failed\n";
  }

$num_entries = ldap_count_entries($ld,$result);
#
# Die if we got no matches, or if we're in batch mode and got more
# than one match
#
exit 2 if ($num_entries == 0);
exit 3 if ($batchmode && ($num_entries > 1));

print "$num_entries matches\n" if ($verbosemode && ($num_entries > 1));

$entry = ldap_first_entry($ld, $result);
if ($num_entries == 1) {
  #
  # If we got just one match, just do it.
  #
  &do_mod_entry($entry);
} else {
  #
  # If we're modifying all entries, loop through and do each one in
  # turn.  Otherwise, make a list of entries so we can present a menu
  # and ask the user which entry to modify.
  #
  while ($entry != 0) {
    if ($modify_all) {
      &do_mod_entry($entry);
    } else {
      push @entries, $entry;
    }
    $entry = ldap_next_entry($ld, $entry);
  }
  #
  # Present a menu of matching entries, and ask which of them the user
  # wants to modify.
  #
  if (! $modify_all) {
    for $cnt (0 .. $#entries) {
      print "$cnt : ", ldap_get_dn($ld, $entries[$cnt]), "\n";
    }
    $num = -1;
    while (($num < 0) || ($num > $#entries)) {
      print "Which entry ? : ";
      $num = <STDIN>;
      chomp $num;
    }
    &do_mod_entry($entries[$num]);
  }
}
########################################
#
# do_mod_entry - Given an entry (as returned by
# ldap_first_entry/ldap_next_entry), apply all the modifications as
# specified in @ARGV
#
sub do_mod_entry {
  my $entry = shift @_;
  my $dn = ldap_get_dn($ld, $entry);
  
  print "\nModifying ", ldap_get_dn($ld, $entry), " :\n" if $verbosemode;
  foreach $mod (@ARGV) {
    my ($attr, $val) = split('=',$mod);
    @values = ldap_get_values($ld,$entry,$attr);
    my (%mods) = ( $attr, $val );
    if (($#values > -1) && ($val eq $values[0])) {
      print "* (no change) $attr=$val\n" if $verbosemode;
      next;
    } elsif (($#values == -1) && ($val eq "")) {
      print "* (no change) $attr not present\n";
      next;
    }
    #
    # Print out nice verbose info on what's going on
    #
    if ($verbosemode) {
      if ($val eq "") {
	if ($#values > -1) {
	  print "- $attr=", $values[0], "\n";
	}
      } elsif ($#values > -1) {
	print "- $attr=", $values[0], "\n";
	print "+ $attr=", $val, "\n";
      } else {
	print "+ $attr=$val\n";
      }
    }
    #
    # Apply this modification - it'd be groovier to assemble a list of
    # modifications so we only call ldap_modify_s once per entry, but
    # it's a bit fiddly to assemble said list properly, so i'm being
    # lazy :)
    #
    if (! $do_nothing) {
      if (ldap_modify_s($ld,$dn,\%mods) != LDAP_SUCCESS) {
	ldap_perror($ld,"ldap_modify_s");
	die "Failed to modify $dn\n";
      } else {
	print "* modifications successful.\n" if $verbosemode;
      }
    }    
  }
}

### ldap_mod_attr ends here
