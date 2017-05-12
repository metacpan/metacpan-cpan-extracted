#!/usr/bin/perl
#
#  web500.pl - Full featured LDAP directory SEARCH, MODIFY, DELETE, ADD
#    Web Interface, with Authentication.
#
#  Author: Clayton Donley, Motorola <donley@cig.mot.com>
#
#  Other Credits:
#   - textarea feature - Douglas Gray Stevens <gray@austin.apc.slb.com>


# Requires the CGI and Net::LDAPapi Modules

use CGI qw(:standard :html3);
use Net::LDAPapi;

# Set to Local LDAP Server and Base DN

$LDAP_SERVER = "localhost";
$LDAP_BASEDN = "o=Org,c=US";

# Set this to the name of the CGI on your web server
$LDAPCGI_NAME = "/cgi-bin/web500.pl";

# This is the displayed title...
$LDAPCGI_TITLE = "Directory Search and Update";

# If set to 0, new passwords will be stored PLAIN TEXT
$LDAPCGI_CRYPT_PASS = 1;

# This is the address that supports your LDAP server
$LDAPCGI_HELP_MAIL = "help\@myorg.com";

# Do you allow users to change their own password?
$LDAPCGI_ALLOW_CHPASS = 1;

# Do you allow users to upload JPEG photos?
$LDAPCGI_ALLOW_JPEGUL = 1;

# Do you want to display Netscape VCARD Entries?
$LDAPCGI_DISPLAY_VCARD = 0;

# This is the default DN and PASSWORD to bind to the LDAP server when
# a user hasn't authenticated.

%ldap_default_auth = (
   "dn", "",
   "pass", "",
);

# %fields - Attribute Table used by all forms
# Format:  "Field Name" => ["Description",length,max_length,multiple,rows]
#   Field Name - Lower Case Attribute Name
#   Description - Name to display to the User
#   length - Length of Field on Screen
#   max_length - Maximum Length of Input
#   multiple - 1 to allow multiple values, 0 for single value
#   rows - Number of Rows to allow for entry.

%fields = (
   "cn"               => ["Name",20,40,1,1],
   "givenname"        => ["First Name",20,40,0,1],
   "sn"               => ["Last Name",20,40,0,1],
   "uid"              => ["UniqueID",10,15,0,1],
   "departmentnumber" => ["Department Number",10,25,0,1],
   "telephonenumber"  => ["Telephone Number",30,50,1,1],
   "facsimiletelephonenumber"
                      => ["Fax Number", 30,50,0,1],
   "pager"            => ["Pager Number", 30,50,0,1],
   "mobile"           => ["Mobile Number", 30,50,0,1],
   "labeleduri"       => ["WWW Home Page", 40,100,0,1],
   "title"            => ["Title", 40,100,0,1],
   "employeenumber"   => ["Employee Number",10,25,0,1],
   "l"                => ["City",30,50,0,1],
   "mail"             => ["Email Address", 25,70,0,1],
   "postaladdress"    => ["Postal Address", 30,200,0,5],
);

# When searching for users, only obtain the following fields
@searchuser_attributes = ("cn","givenname","sn","uid","telephonenumber",
  "facsimiletelephonenumber","mobile","pager","labeleduri","title","mail",
  "postaladdress","employeenumber","l","departmentnumber","jpegphoto");

@searchuser_onattr = ("cn","telephonenumber","uid", "postaladdress","mail",
  "title","departmentnumber","l");

# When adding users, the following attributes may be specified
@adduser_attributes = ("givenname","sn","uid","departmentnumber","mail",
  "telephonenumber","facsimiletelephonenumber","pager","mobile","labeleduri",
  "title","employeenumber");

# When adding users, the following attributes MUST be given
@adduser_required = ("sn","mail");

# When modifying users, the following attributes can be modified.
@modifyuser_attributes = ("departmentnumber","telephonenumber","mail",
  "facsimiletelephonenumber","pager","mobile","labeleduri","title",
  "employeenumber","l","postaladdress");

# When displaying Organizations and Localities below the current point, use
# this search filter.
$DOWN_FILTER = "(|(objectclass=organization)(objectclass=organizationalunit)(objectclass=locality))";

# A List of Location or Organization Names that can be used to map people to
# Certain parts of the Directory Tree.
# Also used by the 'assign_next_uid' routine to assign UserIDs when doing
# directory additions.  You can replace that function with your own method
# of assigning UIDs.
%location = (
	"Finance"   => ["ou=Finance,o=Org,c=US","a","/usr/web/logs/nextid.fin"],
	"HR"        => ["ou=HR, o=Org, c=US","b","/usr/web/logs/nextid.hr"],
	"IS"   	    => ["ou=IS, o=Org, c=US","c","/usr/web/logs/nextid.is"],
);

# @default_person_objectclass is the objectclasses assigned to new users
@default_person_objectclass = ("top","person","organizationalperson","inetorgperson");

# $op will contain our current operation
$op = param('op');

# $searchfor will contain YES if we've performed a search...
$searchfor = param('searchfor');

#
# Operations Requiring no LDAP Access, Binding, or Access Control
#

# Show the Authentication Screen
&authenticate if $op =~ /authenticate/;


#
# Retrieve our Authentication Cookie and put it into our ldap_auth
# hash.  If there is no cookie, we use the default.
#

if (!cookie('ldap_auth_cookie'))
{
   %ldap_auth = %ldap_default_auth;
} else {
   %ldap_auth = cookie('ldap_auth_cookie');
}

#
# Open Our Connection to the LDAP Server...Only place in the whole program.
# We use this $ld as the handle for all LDAP access.
#

$ld = ldap_open($LDAP_SERVER,LDAP_PORT);

#
# If these were passed, we have sent new authorization credentials.
# Put these into our ldap_auth structure, or reset the structure to
# the defaults if the word CLEAR is the UID.
#

if (param('ldap_myuid') && param('ldap_mypass'))
{
   $ldap_myuid = param('ldap_myuid');
   if ($ldap_myuid eq "CLEAR")
   {
      $ldap_auth{'pass'} = $ldap_default_auth{'pass'};
      $ldap_auth{'dn'} = $ldap_default_auth{'dn'};
   } else {
      $ldap_auth{'pass'} = param('ldap_mypass');

# Since the person supplied a UID, not the DN, we lookup the DN
      $ldap_auth{'dn'} = &get_my_dn($ldap_myuid);
   }
}

#
# We now bind to the server using the specified DN and Password
#

if (ldap_simple_bind_s($ld,$ldap_auth{'dn'},$ldap_auth{'pass'})
         != LDAP_SUCCESS)
{
   &print_bad_auth;
   ldap_unbind($ld);
   exit;
}

#
# Lets now build a cookie with our authentication information.  The
# cookie will expire if the browser does not reconnect (and thus resubmit
# a new cookie) within the hour.
#

$ldap_auth_cookie = cookie(  -name => 'ldap_auth_cookie',
                            -value => \%ldap_auth,
                             -path => $LDAPCGI_NAME,
                          -expires => '+4h');

#
# These two functions return NON-HTML mime-types, so we will go there
# directly if necessary rather than send headers and such.
#

&view_jpegphoto if $op =~ /viewjpeg/;
&view_vcard if $op =~ /viewvcard/;

#
# Print the headers and jump to the necessary operation
#

&print_html_headers;
&print_options;
&adduser_entry if $op =~ /adduser/;
&moduser_entry if $op =~ /moduser/;
&deluser_entry if $op =~ /deluser/;
&viewuser_entry if $op =~ /viewuser/ || $op =~ /View Selected/;
&searchuser_results if $op =~ /searchresult/ || $searchfor =~ /yes/;
&help_screen if $op =~ /help/;

# By default, display the search screen...
&searchuser_entry;

# We should NEVER get here, but I've left an unbind and an exit just
# in case.  All of the above subroutines should do EXITs, not RETURNs.

ldap_unbind($ld);
exit;


####
# get_my_dn - Takes UID as argument and returns a matching DN
####

sub get_my_dn
{
   my ($uid) = @_;
   my $dn;
   if (ldap_simple_bind_s($ld,"","") != LDAP_SUCCESS)
   {
      &print_bad_auth;
      ldap_unbind($ld);
      exit;
   }
   $filter = "(uid=$uid)";
   if (ldap_search_s($ld,$LDAP_BASEDN,LDAP_SCOPE_SUBTREE,$filter,
           ["uid"],1,$result) != LDAP_SUCCESS)
   {
      &print_error;
      ldap_unbind($ld);
      exit;
   }
   $ent = ldap_first_entry($ld,$result);
   if ($ent == 0)
   {
      &print_bad_auth;
      ldap_unbind($ld);
      exit;
   }
   $dn = ldap_get_dn($ld,$ent);
}


####
# print_bottom - Print bottom information
####

sub print_bottom
{
   print "Comments and Suggestions to:",
      "<ADDRESS><A HREF=mailto:$LDAPCGI_HELP_MAIL>$LDAPCGI_HELP_MAIL</A></ADDRESS>\n",p;
   print "<h6><strong>$LDAPCGI_TITLE\n",br,
     "Written by Clayton Donley &lt;<a href=mailto:donley\@cig.mot.com>",
     "donley\@cig.mot.com</a>&gt;\n",br,
     "Copyright &copy 1998 by <a href=http://miso.wwa.com/~donley/>Clayton Donley</a>\n",br,
     "All Rights Reserved.</strong></h6>\n";
   return;
}


####
# print_options - Print Top Options
####

sub print_options
{
   local $Flag;
   $Flag=0;
   print "<center><a href=$LDAPCGI_NAME?op=search>[SEARCH]</a>";
   if ($ldap_auth{'dn'} eq $ldap_default_auth{'dn'})
   {
      print "<a href=$LDAPCGI_NAME?op=authenticate>[LOGIN]</a>  ";
      $Flag=1;
   } else {
      print "<a href=$LDAPCGI_NAME?op=searchuser&ldap_myuid=CLEAR&ldap_mypass=CLEAR>[LOGOUT]</a>  ";
      print "<a href=$LDAPCGI_NAME?op=moduser>[CHANGE PASSWORD/INFO]</a>  ";
      print "<a href=$LDAPCGI_NAME?op=adduser>[ADD]</a>  ";
   }
   print "<a href=$LDAPCGI_NAME?op=help>[HELP]</a></center>",p;
   if ($Flag) {
	print "NOTE: Please LOGIN before you change password and other information.<br><br>";
   }
   return;
}


####
# searchuser_entry - The main search screen
####

sub searchuser_entry
{

# If 'my_base_dn' is passed, use it, otherwise use the default

   if (param('my_base_dn'))
   {
      $my_base_dn = param('my_base_dn');
   } else {
      $my_base_dn = $LDAP_BASEDN;
   }

# Get rid of extra spaces after commas.  This probably isn't the
# safest way to do this, but should be okay for now.

   $my_base_dn =~ s/,\s/,/g;

# Now make sure that anything passed contains our default BASEDN, otherwise
# 'my_base_dn' may not be useful.

   if ($my_base_dn !~ /$LDAP_BASEDN$/)
   {
      $my_base_dn = $LDAP_BASEDN;
   }

# Splits the DN into segments.  Netscape makes this easy with ldap_explode_dn,
# but I have to do it manually because none of the other SDKs support it.
# We're building a hash with all the levels above our own for use in the
# popup_menu.

   @splitbase = split(/,/,$my_base_dn);
   @splitdefault = split(/,/,$LDAP_BASEDN);

   for ($count = 0; $count <= $#splitbase; $count++)
   {
      for ($base_count = $count; $base_count <= $#splitbase; $base_count++)
      {
         if ($count != $base_count)
         {
            $base_vals[$count] = $base_vals[$count] . ",";
         }
         $base_vals[$count] = $base_vals[$count] . $splitbase[$base_count];
      }
      $shortname = $splitbase[$count];
      $shortname =~ s/^.*=//;
      $basename{$base_vals[$count]} = $shortname;
   }

# We don't want people to be able to go higher than the default level.
   $#base_vals = $#base_vals - $#splitdefault;

# Now print the form with the query and the popup containing higher
# levels within the LDAP tree.

   print "<b>Current Search Base:</b> $my_base_dn",
     start_form,
     hidden('op','searchresult'),
     hidden('searchfor','yes'),
     "Move Up To: ",popup_menu('my_base_dn',\@base_vals,$base_vals[0],\%basename),p;
   foreach $searchattr (@searchuser_onattr)
   {
      print textfield(-name=>"searchfor_$searchattr",-size=>50),
      $fields{$searchattr}[0],"\n",br;
   }
   print p,submit('Search'),reset('Reset'),
   end_form,p,"\n";

# This search will find all the organizations and localities one level below
# our current level.  This allows people to navigate downwards.

   if (ldap_search_s($ld,$my_base_dn,LDAP_SCOPE_ONELEVEL,$DOWN_FILTER,[],1,$result) != LDAP_SUCCESS)
   {
      &print_error;
      ldap_unbind($ld);
      exit;
   }

   print h3("Move Down To:\n");
   print "<ul>\n";
   $entrycount = 0;
   for ($ent=ldap_first_entry($ld,$result);$ent!=0;$ent=ldap_next_entry($ld,$ent))
   {
      $entrycount = $entrycount + 1;
      $newbase = ldap_get_dn($ld,$ent);
      $subbase = $newbase;

# We need to escape certain special characters.  I'm sure there are more
# than these, but this was all I could think of for now.
      $subbase =~ s/ /%20/g;
      $subbase =~ s/=/%3D/g;

# We simply pass parameters that would change my_base_dn and continue searching
      print "<li><a href='$LDAPCGI_NAME?op=searchuser&my_base_dn=$subbase'>$newbase</a>\n";
   }
   if ($entrycount == 0)
   {
      print "<li>Nothing Below\n";
   }
   print "</ul>\n",hr;

   &print_bottom;
   ldap_unbind($ld);
   exit;
}

sub searchuser_results
{
   $filter = "";
   $noattrs = 0;
   
   foreach $searchattr (@searchuser_onattr)
   {
      if (param("searchfor_$searchattr"))
      {
         $noattrs++;
         $filter = $filter . "($searchattr=*" . param("searchfor_$searchattr") .  "*)";
      }
   }

   if ($filter ne "")
   {
      if ($noattrs > 1)
      {
         $fullfilter = "(&$filter)";
      } else {
         $fullfilter = $filter;
      }
   } else {
      &searchuser_entry;
   }

   $my_base_dn = param('my_base_dn');

   if (ldap_search_s($ld,$my_base_dn,LDAP_SCOPE_SUBTREE,$fullfilter,[],0,$result) != LDAP_SUCCESS)
   {
      ldap_perror($ld,"Search");
      &print_error;
      ldap_unbind($ld);
      exit;
   }
   print h3("Results: Search of $my_base_dn for $fullfilter");

# We're going to display the results in a table so that they line-up
# nicely.

   print start_form,"<table border width=500>\n";
   print "<TR><TD>No.</TD><TD>Name</TD><TD>Location</TD><TD>Email</TD></TR>\n";
   $entrycount = 0;

# This for loop cycles through all the entries.

   for ($ent = ldap_first_entry($ld,$result); $ent != 0;
     $ent = ldap_next_entry($ld,$ent))
   {
      $entrycount = $entrycount + 1;
      $fulldn = ldap_get_dn($ld,$ent);
      $realdn = $fulldn;

# Once again, we're going to escape special characters
      $fulldn =~ s/ /%20/g;
      $fulldn =~ s/=/%3D/g;

# In a later version I'll make these defined at the beginning, but
# these are the fields for the short listing.
      @cn = ldap_get_values($ld,$ent,"cn");
      @l = ldap_get_values($ld,$ent,"l");
      @mail = ldap_get_values($ld,$ent,"mail");
      @labeleduri = ldap_get_values($ld,$ent,"labeleduri");
      @jpegphoto = ldap_get_values($ld,$ent,"jpegphoto");

# Each listing has a checkbox with the value of the person's DN
      print "<TR><TD>",checkbox('selectdn',0,$realdn,$entrycount),"</TD>";

# If the person has a 'labeleduri' field, make the person's CN a hyperlink
# to their WWW page.

      if ($#labeleduri >= 0)
      {
         print "<TD><a href=$labeleduri[0]>$cn[0]</a></TD>";
      } else {
         print "<TD>$cn[0]</TD>";
      }
      print "<TD>$l[0]</TD>";

# If the person has a registered EMAIL address, display it and make it
# a 'mailto' URL.

      if ($#mail >= 0)
      {
         print "<TD><a href=mailto:$mail[0]>$mail[0]</a></TD>";
      } else {
         print "<TD></TD>";
      }

# Allow full details of the user to be viewed.
      print "<TD><a href='$LDAPCGI_NAME?op=viewuser&selectdn=$fulldn'>View All</a></TD>";

# Only display Modify and Delete options if we have authenticated.
      if ($ldap_auth{'dn'} ne $ldap_default_auth{'dn'})
      {
         print "<TD><a href='$LDAPCGI_NAME?op=moduser&selectdn=$fulldn'>Modify</a></TD>";
         print "<TD><a href='$LDAPCGI_NAME?op=deluser&selectdn=$fulldn'>Delete</a></TD>";
      }

# If we are displaying Netscape VCARDs, display that option.
      if ($LDAPCGI_DISPLAY_VCARD)
      {
         print "<TD><a href='$LDAPCGI_NAME?op=viewvcard&selectdn=$fulldn'>View Vcard</a></TD>";
      }

# If the person has a Jpeg Photo, give an option to display it.
      if ($#jpegphoto >= 0)
      {
         print "<TD><a href='$LDAPCGI_NAME?op=viewjpeg&selectdn=$fulldn'>View Photo</a></TD>";
      }
      print "</TR>\n";
   }
   print "</TABLE>\n",p;
   if ($entrycount == 0)
   {
      print "No Matches\n",end_form,hr;
   } else {
      print submit("op","View Selected"),end_form,hr;
   }

   &print_bottom;
   ldap_unbind($ld);
   exit;
}

####
# Modify User
####

sub moduser_entry
{

   if ($ldap_auth{'dn'} eq $ldap_default_auth{'dn'})
   {
      print "Please <a href=$LDAPCGI_NAME?op=authenticate>Authenticate</a>.";
      ldap_unbind($ld);
      exit;
   }

   if (param('selectdn'))
   {
      $selectdn = param('selectdn');
   } else {
      $selectdn = $ldap_auth{'dn'};
   }

   print "<b>Modifying:</b> $selectdn",br;

   if (param('gomodifyit'))
   {
      &gomodifyit;
   }

   if (ldap_search_s($ld,$selectdn,LDAP_SCOPE_BASE,"objectclass=*",[],0,$result)
     != LDAP_SUCCESS)
   {
      &print_error;
      ldap_unbind($ld);
      exit;
   }

   $ent = ldap_first_entry($ld,$result);

   if ($ent == 0)
   {
      print "User Not Found...\n",p;
      ldap_unbind($ld);
      exit;
   }

#  Cycle through all attributes and place their values in a hash.

   for ($attr = ldap_first_attribute($ld,$ent,$ber); $attr; $attr =
ldap_next_attribute($ld,$ent,$ber))
   {
      @vals = ldap_get_values($ld,$ent,$attr);
      $record{$attr} = [ @vals ];
   }

#  Draw up the Web Form

   print start_multipart_form,
    hidden('op','moduser'),
    hidden('selectdn',$selectdn),
    hidden('gomodifyit','yes');

   print hr,"<TABLE>";

#  Password is a Special Case.  Since it needs special processing, we
#  do not include it in %fields and thus request it separately.

   print "  <TR><TD VALIGN=TOP>New Password:</TD><TD VALIGN=TOP>",password_field('pass'),"</TD></TR>\n";
   print "  <TR><TD VALIGN=TOP>New Password (again):</TD><TD VALIGN=TOP>",password_field('pass2'),"</TD></TR>\n";
   print "</TABLE><hr><TABLE>\n";

#  Now cycle through all keys in %fields and construct the form for each
#  attribute to be modified through this page.

   foreach $key (@modifyuser_attributes)
   {
      $count = 0;
      for $value ( @{$record{$key}} )
      {
         if ($count == 0)
         {
            print "  <TR><TD VALIGN=TOP>" . $fields{$key}[0] . ":</TD>";
         } else {
            print "  <TR><TD VALIGN=TOP></TD>";
         }
         # Sun 24-Aug-1997; Douglas Gray Stephens 
         #  Add option for textarea
         if ($fields{$key}[4]>1)
         {
           print "  <TD VALIGN=TOP>",textarea("$key.$count",$value,$fields{$key}[4],$fields{$key}[1],"","wrap=virtual"),"</TD></TR>\n";
         } else {
           print "  <TD VALIGN=TOP>",textfield("$key.$count",$value,$fields{$key}[1],$fields{$key}[2]),"</TD></TR>\n";
         }
         print hidden("$key.$count.orig",$value);
         $count++;
      }
      if ($fields{$key}[3] == 1 || $count == 0)
      {
         # Sun 24-Aug-1997; Douglas Gray Stephens 
         #  Add option for textarea
         if ($count == 0)
         {
            print "  <TR><TD VALIGN=TOP>" . $fields{$key}[0] . ":</TD>";
         } else {
            print "  <TR><TD VALIGN=TOP></TD>";
         }
         if ($fields{$key}[4]>1)
         {
            print "  <TD VALIGN=TOP>",textarea("$key.$count",$value,$fields{$key}[4],$fields{$key}[1],"","wrap=virtual"),"</TD></TR>\n";
         } else {
            print "  <TD VALIGN=TOP>",textfield("$key.$count",$value,$fields{$key}[1],$fields{$key}[2]),"</TD></TR>\n";
         }
      }
      print hidden($key,$count);
   }
   if ($LDAPCGI_ALLOW_JPEGUL)
   {
      print "  <TR><TD VALIGN=TOP>Upload Photo (JPEG)</TD><TD VALIGN=TOP>",
        filefield('jpegphoto','',35,256),"</TD></TR>\n";
      print "  <TR><TD VALIGN=TOP></TD><TD VALIGN=TOP>(Enter 'REMOVE' to delete current image)</TD></TR>";
   }
   print "</TABLE>",hr,submit('Modify Entry'), end_form,hr;

   &print_bottom;
   ldap_unbind($ld);
   exit;
}

####
# gomodifyit - Routine to actually do the User Modification
####

sub gomodifyit
{
   print hr;

   foreach $key (@modifyuser_attributes)
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

   if ($LDAPCGI_ALLOW_CHPASS)
   {
      $pass = param("pass");
      $pass2 = param("pass2");

      if ($pass ne "")
      {
         if ($pass eq $pass2)
         {
            if ($LDAPCGI_CRYPT_PASS)
            {
               $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
               srand( time() ^ ($$ + ($$ << 15)));
               $salt = "";
               for ($i = 0; $i <2; $i++)
               {
                  $saltno = int rand length($chars);
                  $mychar = substr($chars,$saltno,1);
                  $salt = $salt . $mychar;
               }
               $encpass = crypt $pass, $salt;
               $ldapmod{'userpassword'} = "{CRYPT}" . $encpass;
            } else {
               $ldapmod{'userpassword'} = $pass;
            }
            if ($ldap_auth{'dn'} eq $selectdn)
            {
               print "<b>NOTICE:</b> You must <a href=",
                 "$LDAPCGI_NAME?op=authenticate>Re-Authenticate</a> to",
                 " make other modifications.",p;
            }
         } else {
            print "<b>WARNING:</b> Passwords did NOT match (not changed)!",p;
         }
      }
   }

   if ($LDAPCGI_ALLOW_JPEGUL)
   {
      if (($filename = param('jpegphoto')))
      {
         if ($filename =~ /^remove$/i)
         {
            $ldapmod{'jpegphoto'} = "";
         } else {
            $jpegimg = "";
            while (read($filename,$buffer,1024))
            {
               $jpegimg = $jpegimg . $buffer;
            }
            $ldapmod{'jpegphoto'} = {"rb",[$jpegimg]};
         }
      }
   }

   if (ldap_modify_s($ld,$selectdn,\%ldapmod) != LDAP_SUCCESS)
   {
      &print_error;
      ldap_unbind($ld);
      exit;
   }

   &post_modify_routine;

   print "<b>Entry Modified...</b>\n";
   return;
}
      

####
# Add User
####

sub adduser_entry
{
   if ($ldap_auth{'dn'} eq $ldap_default_auth{'dn'})
   {
      print "Please <a href=$LDAPCGI_NAME?op=authenticate>Authenticate</a>.";
      ldap_unbind($ld);
      exit;
   }

   if (param('addit'))
   {
      &add_one_user;
      ldap_unbind($ld);
      exit;
   }

   @locations = sort keys %location;

   print start_form,
      hidden('op','adduser'),
      hidden('addit','yes'),
      hr,
      "<table>",
      "<TR><TD VALIGN=TOP>Password:</TD><TD>",password_field('pass'),"</TD></TR>\n",
      "<TR><TD VALIGN=TOP>Password (again):</TD><TD>",password_field('pass2'),"</TD></TR>\n",
      "</TABLE>",hr,"<TABLE>";

   foreach $key (@adduser_attributes)
   {
      print "  <TR><TD VALIGN=TOP>" . $fields{$key}[0] . ":</TD>";
      if ($fields{$key}[4] > 1)
      {
         print "  <TD VALIGN=TOP>",textarea("$key","",$fields{$key}[4],$fields{$key}[1],"","wrap=virtual"),"</TD></TR>\n";
      } else {
         print "  <TD VALIGN=TOP>",textfield("$key","",$fields{$key}[1],$fields{$key}[2]),"</TD></TR>\n";
      }
   }
   print "  <TR><TD VALIGN=TOP>Location:</TD><TD VALIGN=TOP>",radio_group('l',[@locations],$locations[0],'true');
   print "</TABLE>",hr,submit('Add'),reset('Reset'),end_form,hr;
   ldap_unbind($ld);
   exit;
}

####
# Routine to Add One User
####     

sub add_one_user
{
   if (length(param('pass')) < 6)
   {
      print "Password must be at least 6 characters in length.\n";
      return;
   }
   if (param('pass') ne param('pass2'))
   {
      print "Passwords did not match, please try again.\n";
      return;
   }

   $pass = param('pass');
   if ($LDAPCGI_CRYPT_PASS)
   {
      $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
      srand(time()^($$+($$<<15)));
      $salt = "";
      for ($i = 0; $i <2; $i++)
      {
         $saltno = int rand length($chars);
         $mychar = substr($chars,$saltno,1);
         $salt = $salt . $mychar;
      }
      $encpass = crypt $pass, $salt;
      $ldapmod{'userpassword'} = "{CRYPT}" . $encpass;
   } else {
      $ldapmod{'userpassword'} = $pass;
   }

   foreach $key (@adduser_attributes)
   {
      if (param($key) ne "")
      {
         $ldapmod{$key} = param($key);
      }
   }

   foreach $key (@adduser_required)
   {
      if ($ldapmod{$key} eq "")
      {
         print "Missing Required Field: $key\n",p;
         ldap_unbind($ld);
         exit;
      }
   }

   $ldapmod{'objectclass'} = [ @default_person_objectclass ];

   $l = param('l');
   $ldapmod{'l'} = $l;

   if ($ldapmod{'uid'} eq "")
   {
      $ldapmod{'uid'} = &assign_next_uid($l);
   }

   &verify_unique;
   
   $cn = $ldapmod{'givenname'} . " " . $ldapmod{'sn'};
   $uid = $ldapmod{'uid'};
   $long_cn = $cn . "-" . $uid;

   $ldapmod{'cn'} = [ ($long_cn, $cn) ];

   $add_dn = "cn=" . $long_cn . "," . $location{$l}[0];

   if (ldap_add_s($ld,$add_dn,\%ldapmod) != LDAP_SUCCESS)
   {
      &print_error;
      ldap_unbind($ld);
      exit;
   }

   &post_add_routine;

   print "<b>Entry Added...</b>\n",p;
   print "DN: $add_dn\n",br;
   print "UID: $uid\n",p;

   return;
}

sub assign_next_uid
{
   my ($loc) = $_;

   open(READNEXTID,$location{$l}[2]);
   $nextid = <READNEXTID>;
   close (READNEXTID);
   chop $nextid;
   $uid = $location{$l}[1] . $nextid;

   open(WRITENEXTID,">$location{$l}[2]");
   print WRITENEXTID $nextid+1 . "\n";
   close(WRITENEXTID);

   return $uid;
}

####
# Delete User
####

sub deluser_entry
{
   $selectdn = param('selectdn');
   if ($selectdn eq "")
   {
      print "Nothing to Delete.\n";
      return;
   }
   print h3("Delete User: $selectdn");

   if (!param('confirm'))
   {
      print start_form,
        hidden('op','deluser'),
        hidden('confirm','yes'),
        hidden('selectdn',$selectdn),
        "WARNING! This will PERMANENTLY remove the entry for:\n",p,
        $selectdn,p,
        "Please confirm or click BACK on your browser to cancel.\n",p,
        submit('Confirm'),
        end_form;
      ldap_unbind($ld);
      exit;
   }

   if (ldap_delete_s($ld,$selectdn) != LDAP_SUCCESS)
   {
      &print_error;
      ldap_unbind($ld);
      exit;
   }

   &post_delete_routine;

   print "DELETED!\n",p,hr;
   &print_bottom;
   ldap_unbind($ld);
   exit;
} 

####
# Display Full User Entry
####

sub viewuser_entry
{
   @selectdn = param('selectdn');
   foreach $currentdn (@selectdn)
   {
      if (ldap_search_s($ld,$currentdn,LDAP_SCOPE_BASE,"(objectclass=*)",
        \@searchuser_attributes,0,$results) != LDAP_SUCCESS)
      {
         &print_error;
         ldap_unbind($ld);
         exit;
      }
      $ent = ldap_first_entry($ld,$results);
      print h3("$currentdn");

      print "<TABLE>\n";
      for ($attr = ldap_first_attribute($ld,$ent,$ber); $attr ne "";
        $attr = ldap_next_attribute($ld,$ent,$ber))
      {
         if ($attr eq "jpegphoto")
         {
            $fulldn = $currentdn;
            $fulldn =~ s/ /%20/g;
            $fulldn =~ s/=/%3D/g;
            print "<TR><img src='$LDAPCGI_NAME?op=viewjpeg&selectdn=$fulldn'></TR>\n";
         } else {
            @vals = ldap_get_values($ld,$ent,$attr);
            print "<TR>";
            if ($fields{$attr})
            {
               print "<TD>$fields{$attr}[0]:</TD>";
            } else {
               print "<TD>$attr:</TD>";
            }
            for ($count = 0; $count <= $#vals; $count++)
            {
               if ($attr eq "mail")
               {
                  print "<TD><a href=mailto:$vals[$count]>$vals[$count]</a></TD>";
               } elsif ($attr eq "labeleduri") {
                  print "<TD><a href=$vals[$count]>$vals[$count]</a></TD>";
               } else {
                  $vals[$count] =~ s/\n/<br>/g;
                  print "<TD>$vals[$count]</TD>";
               }
            }
            print "</TR>\n";
         }
      }
      print "</TABLE>\n",hr;
   }
   &print_bottom;
   ldap_unbind($ld);
   exit;
}


####
# Display jpegPhoto
####

sub view_jpegphoto
{

# Print the image/jpeg Header
   print header('image/jpeg');

# $selectdn is our currently selected DN.
   $selectdn = param('selectdn');

# We perform a search for the 'jpegphoto' attribute.
   if (ldap_search_s($ld,$selectdn,LDAP_SCOPE_BASE,"objectclass=*",
     ['jpegphoto'],0,$result) != LDAP_SUCCESS)
   {
      &print_error;
      ldap_unbind($ld);
      exit;
   }

# Only one entry should match.
   $ent = ldap_first_entry($ld,$result);

# We use ldap_get_values_len, since jpegphoto is binary.
   @pics = ldap_get_values_len($ld,$ent,"jpegphoto");

# Print the picture data to STDOUT if it exists.
   if ($#pics >= 0)
   {
      print $pics[0];
   }

   ldap_unbind($ld);
   exit;
}

####
# Print Authentication Form
####

sub authenticate
{
   print header;
   print start_html;
   print h2("Directory Authentication");

# Print the Authentication Form
   print start_form(-action=>"$LDAPCGI_NAME"),
         "Login: ",textfield('ldap_myuid'),p,
         "Password: ",password_field('ldap_mypass'),p,
         submit('Login'),
         end_form,hr;
   &print_bottom;
   exit;
}


####
# Print Basic HTML Headers, including Authentication Cookie
####

sub print_html_headers
{

# Notice that we print the Cookie containing the authentication information.
   print header(-cookie=> $ldap_auth_cookie);
   print start_html($LDAPCGI_TITLE),h1($LDAPCGI_TITLE);

# If the person has authenticated, let them know we know who they are.
   if ($ldap_auth{'dn'} ne $ldap_default_auth{'dn'})
   {
      @splitdn = split(/,/,$ldap_auth{'dn'});
      $name = $splitdn[0];
      $name =~ s/.*=//;
      print "<b>Welcome, $name!</b>",hr;
   }
}

####
# Print the LDAP Error Message
####

sub print_error
{
# ldap_get_lderrno is a Netscape SDK call, but I've made a dummy version
# for the PERL module, as we need some way to get the numerical error code.
   $lderr = ldap_get_lderrno($ld,$blah1,$blah2);
   $errmsg = ldap_err2string($lderr);
   print p,"\nError: $errmsg\n",p,hr;
   &print_bottom;
   return;
}

sub help_screen
{
   print "Online Help is Net Yet Implemented.",p,hr;
   &print_bottom;
   exit;
}

sub print_bad_auth
{
   print header;
   print start_html("Login/Password Incorrect");
   print h1("Login/Password Incorrect");
   print "Please <a href=$LDAPCGI_NAME?op=authenticate>Authenticate</a> again.\n",p,hr;
   &print_bottom;
   return;
}

######
# post_*_routine is used for any actions you want to perform after doing
#   any of these functions.  Useful for email/logging and synchronization
#   purposes that you may have.
######

sub post_add_routine
{
   return;
}

sub post_modify_routine
{
   return;
}

sub post_delete_routine
{
   return;
}
