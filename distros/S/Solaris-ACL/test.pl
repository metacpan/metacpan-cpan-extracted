# $Id: test.pl,v 1.10 2000/04/07 22:37:02 ian Exp $

# Change Log:
# $Log: test.pl,v $
# Revision 1.10  2000/04/07 22:37:02  ian
# Added group entries to the test ACLs
#
# Revision 1.9  2000/02/13 21:31:53  ian
# Fixed typo in test.pl
# The version 0.03 release
# Using cvs2cl to create ChangeLog (though these comments only show up in
# next commit...)
#
# Revision 1.8  2000/02/07 01:26:54  iroberts
# * Added Id and Log strings to all files
# * Now EXPORTs instead of EXPORT_OKing setfacl and getfacl
# * make clean now removes test-acl-file and test-acl-dir
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Solaris::ACL;
$loaded = 1;
print "ok 1\n";

use Data::Dumper;
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$FILE_NAME = "test-acl-file";
$DIR_NAME = "test-acl-dir";

if (-f $FILE_NAME) {unlink $FILE_NAME};	# make a new empty file
open (FILE, ">$FILE_NAME"); close FILE;

if (-d $DIR_NAME) {rmdir $DIR_NAME}; # make a new empty directory
mkdir ($DIR_NAME, 0777) || die "mkdir ($DIR_NAME,0777) failed";

$acl = new Solaris::ACL(0751);
$acl->mask(4);
for $i (0..7)
{
    $acl->users($i+10,$i);
    $acl->groups($i+20, $i);
}
$acl->calc_mask;

$def_acl = new Solaris::ACL(0751);
for $i (0..7)
{
    $def_acl->users($i+10,$i);
    $def_acl->groups($i+20,$i);
}
$def_acl->calc_mask;

if(!Solaris::ACL::setfacl($FILE_NAME, $acl))
{
    print "not ok 2: $Solaris::ACL::error\n";
}
else
{
    print "ok 2\n";
}

($ret_acl, $ret_def_acl) = Solaris::ACL::getfacl($FILE_NAME);


if(!defined($ret_acl))
{
    print "not ok 3: $Solaris::ACL::error\n";
}
elsif(defined($ret_def_acl))
{
    print "not ok 3: returned a default acl for a file\n";
}
else # check if %$ret_acl and %$acl are the same
{
    if($ret_acl->equal($acl))
    {
	print "ok 3\n";
    }
    else
    {
	print "not ok 3: return of getfacl differs from setfacl args.\n";
    }
}

if(!Solaris::ACL::setfacl($DIR_NAME, $acl, $def_acl))
{
    print "not ok 4: $Solaris::ACL::error\n";
}
else
{
    print "ok 4\n";
}

($ret_acl, $ret_def_acl) = Solaris::ACL::getfacl($DIR_NAME);
if(!defined($ret_acl))
{
    print "not ok 5: $Solaris::ACL::error\n";
}
elsif(!defined($ret_def_acl))
{
    print "not ok 5: returned no default acl\n";
}
else # check if %$ret_acl and %$acl are the same
{
    if(!($ret_acl->equal($acl)))
    {
	print "ok 5: return of getfacl differs from setfacl args\n";
    }
    elsif(!(($def_acl)->equal($ret_def_acl)))
    {
	print "not ok 5: default return of getfacl differs from setfacl args.\n";
    }
    else
    {
	print "ok 5\n";
    }
}
