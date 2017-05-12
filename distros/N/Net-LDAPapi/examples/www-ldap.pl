#!/usr/bin/perl
#
#  www-ldap.pl - CGI script to allow users with passwords to authenticate
#      and modify their own accounts on an LDAP server.
#
#  Requires: PERL5 LDAP Module
#            CGI.pm Module 
#
#  Author:  Clayton Donley <donley@cig.mot.com>
#


use CGI qw(:standard);
use Net::LDAPapi;

#
#  These are the only lines you should need to change for normal
#  operation.  You'll need to change part of the &bind subroutine if
#  you don't use 'uid' as your unique identifier.
#

$BASEDN = "o=Org, c=US";		# Set to your top level
$ldap_server = "localhost";		# Set to your LDAP server
$problem_mail = "root\@localhost";	# Set to a help desk mail address
$program_url = "/cgi-bin/www-ldap.pl";	# URL for this program

#  The layout for the %field hash is as followed:
#
#      "attribute",["Description", display_length, max_length, multiple],
#
#  attribute	   ->  Lower Case Attribute Name
#  Description     ->  Description of Field for End User
#  display_length  ->  Number of Columns to Display for Attribute
#  max_length      ->  Most Characters to Accept for Attribute
#  multiple        ->  1 = Multiple Value Attribute, 0 = Single Value Attributes

%field = (
	"departmentnumber",["Department Number", 10,25,0],
	"telephonenumber",["Telephone Number", 30, 50,1],
	"facsimiletelephonenumber",["Fax Number", 30, 50,0],
	"pager",["Pager Number", 30, 50,0],
	"mobile",["Mobile Number", 30, 50,0],
	"labeleduri",["WWW Home Page", 50, 100,1],
	"title",["Title",50,100,0],
	"employeenumber",["Employee Number",10,25,0],
	"l",["City",30,50,0],
);

#  END OF SUGGESTED MODIFICATION AREA

print header;

if (!param())
{
	&web_authenticate;
	&byline;
	exit;
} else {
	$ldap_bind_uid = param('login');
	$ldap_bind_password = param('password');
	if ($ldap_bind_uid ne "" && $ldap_bind_password ne "")
	{
	   if (&bind < 0)
	   {
	      &incorrect_login;
	   }
	} else  {
	   &incorrect_login;
	}
	&modify_screen;
	$ld->unbind;
	&byline;
	exit;
}

sub byline
{
	print hr,"LDAP Account Management Tool by <em><a href=mailto:donley\@cig.mot.com>Clayton Donley</a></em>\n",p;
	return;
}

sub incorrect_login
{
	print start_html('Invalid Username or Password'),
		h1('Invalid Username or Password'),
		"The Login or Password you supplied was incorrect.  Please ",
		"click <a href=" . $program_url . ">HERE</a> and try again.\n";
	exit;
}

sub web_authenticate
{
	print start_html('LDAP Account Maintenance'),
		h1('LDAP Account Maintenance'),
		"For Problems with this service, please email <a href=$problem_email>$problem_email</a>.",hr,
		start_form,
		"Login:  ",textfield('login'),
		p,
		"Password:  ",password_field('password'),
		p,
		submit('Login'),
		end_form;
}

sub bind
{

#  First initialize our connection to the LDAP Server and bind anonymously.

	$ld = new Net::LDAPapi($ldap_server);

	if ($ld->bind_s != LDAP_SUCCESS)
	{
	   print "Error:  Unable to Bind Anonymously to the Directory.",p;
	   print "bind_s: $ld->errstring\n";
	   $ld->unbind;
	   return;
	}

#  Since we've entered our UID, not our CN, we must first find the DN of a
#  person who matches the UID in $ldap_bind_uid
 
        @attrs = ("cn");
        $filter = "(uid=$ldap_bind_uid)";
        if ($ld->search_s($BASEDN,LDAP_SCOPE_SUBTREE,$filter,\@attrs,1)
           != LDAP_SUCCESS)
        {
           print "Error:  Unable to Search Directory.",p;
	   print "search_s: $ld->errstring\n";
	   $ld->unbind;
	   exit -1;
        }

#  Obtain a pointer to the first entry matching our query.  We are making the
#  assumption that since UID means Unique ID that this is the only time we
#  need to do this.
 
        $ld->first_entry;

        if ($ent != 0)
        {

#  We only need the DN from the entry we matched.

	   $dn = $ld->get_dn;

#  Attempt to bind with the DN and Password supplied previously.

	  if ($ld->bind_s($dn,$ldap_bind_password) != LDAP_SUCCESS)
          {
	      $ld->unbind;
	      return -1;  # Return Failure
	  }
          return 0;  # Return Success
	}
	$ld->unbind;
	return -1;  # Return Failure
}

sub modify_screen
{

#  Print WWW Header

       print start_html("LDAP Account Management for '$ldap_bind_uid'"),
        h1("LDAP Account Management for: '$ldap_bind_uid'");

#  If we've just made changes, jump to the Modify routine.

	if (param('gomodifyit'))
	{
	   &gomodifyit;
	}

#  Find values for all attributes.  Should probably change this.

	@attrs = ();

#  Set the query filter to be the userid specified previously

	$filter = "(uid=$ldap_bind_uid)";

#  Perform Synchronous LDAP Search

	if ($ld->search_s($dn,LDAP_SCOPE_BASE,$filter,\@attrs,0)
          != LDAP_SUCCESS)
	{
	   print "search_s: $ld->errstring\n",p;
	   print "Error:  Unable to Search.\n";
	   exit;
	}

#  Since we queried within a specific DN, we will get only 1 match...Put
#  a pointer to that match in $ent

	$ld->first_entry;

#  This should never happen in normal use...

	if ($ent == 0)
	{
           print "User Not Found...\n",p;
           return;
        }

#  Cycle through all attributes and place their values in a hash.

	for ($attr = $ld->first_attribute; $attr; $attr = $ld->next_attribute)
	{
	   @vals = $ld->get_values($attr);
           $record{$attr} = [ @vals ];
        }

#  Draw up the Web Form

	print start_form,
	 hidden('login',param('login')),
	 hidden('password',param('password')),
	 hidden('gomodifyit','yes');

	print hr,"<TABLE>";

#  Password is a Special Case.  Since it needs special processing, we
#  do not include it in %fields and thus request it separately.

	print "  <TR><TD>New Password:</TD><TD>",password_field('pass'),"</TD></TR>\n";
	print "  <TR><TD>New Password (again):</TD><TD>",password_field('pass2'),"</TD></TR>\n";
	print "</TABLE><hr><TABLE>\n";

#  Now cycle through all keys in %field and construct the form for each
#  attribute to be modified through this page.

	foreach $key (sort keys %field)
        {
	   $count = 0;
	   for $value ( @{$record{$key}} )
	   {
	      if ($count == 0)
	      {
	         print "  <TR><TD>" . $field{$key}[0] . ":</TD>";
	      } else {
	         print "  <TR><TD></TD>";
	      }
	      print "  <TD>",textfield("$key.$count",$value,$field{$key}[1],$field{$key}[2]),"</TD></TR>\n";
	      print hidden("$key.$count.orig",$value);
	      $count++;
	   }
	   if ($field{$key}[3] == 1 || $count == 0)
	   {
	      if ($count == 0)
	      {
	         print "  <TR><TD>" . $field{$key}[0] . ":</TD>";
	      } else {
	         print "  <TR><TD></TD>";
	      }
	      print "<TD>",textfield("$key.$count","",$field{$key}[1],$field{$key}[2]),"</TD></TR>\n";
	   }
	   print hidden($key,$count);
	}
	print "</TABLE>",hr, submit('Modify Entry'),
	end_form;
	return;
}


#
#  Routine to actually modify an LDAP entry. Must have already used the
#  &bind subroutine to bind to the server.
#

sub gomodifyit
{

	print hr;

#  Build a hash of arrays for the LDAP Modification

	foreach $key (sort keys %field)
	{
	   $change = 0;
	   @vals = ();
	   $realcount = 0;
	   for ($count = 0; $count <= param($key); $count++)
	   {
	      if (param("$key.$count") ne "")
	      {
	         $vals[$realcount] = param("$key.$count");
	         $realcount++;
	      }
              if (param("$key.$count.orig") ne param("$key.$count"))
              {
                 $change = 1;
              }

	   }

#  If there is no values, pass an empty scalar.

	   if ($change == 1)
	   {
	      if ($#vals < 0)
	      {
	         $ldapmod{$key} = "";
	      } else {
	         $ldapmod{$key} = [ @vals ];
	      }
	   }
	}

#  Lets Check the Password... If non-empty, encrypt and add to %ldapmod

	$pass = param("pass");
	$pass2 = param("pass2");

	if ($pass eq "")
	{
	} else {
	   if ($pass eq $pass2)
	   {
# Encrypt as necessary...
	     if ($ENCRYPT_PASS == 1)
	     {
	      $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

#  Seeding with time and proccess id is not normally recommended, but we're
# only generating the salt, not the password.

	      srand( time() ^ ($$ + ($$ << 15)) );
	      $salt = "";
	      for ($i = 0; $i <2; $i++)
	      {
	         $saltno = int rand length($chars);
	         $mychar = substr($chars,$saltno,1);
	         $salt = $salt . $mychar;
	      }
	      $pass = crypt $pass, $salt;
	     }
	     $ldapmod{'userPassword'} = "{CRYPT}" . $pass;
	     print "<b>Warning:</b> Click <a href=" . $program_url . ">HERE</a> and login using your new password if you plan to make other changes...\n",p;
	   } else {
	      print "<b>Warning:</b> Passwords Did Not Match...Not Changed...\n",p;
	   }
	}

#  Perform a synchronous MODIFY operation on our $dn

	@change_keys = keys %ldapmod;
	if ($#change_keys >= 0)
	{
	   if ($ld->modify_s($dn,\%ldapmod) != LDAP_SUCCESS)
	   {
	      print "\n",p,"Error: Unable to Modify Entry...\n",p;
	      print "modify_s: $ld->errstring\n";
	      exit;
	   }
#  Success!
	   print "<b>Entry Modified...</b>\n";
	   return;
	} else {
	   print "<b>No Changes Made...</b>\n";
	}
}
