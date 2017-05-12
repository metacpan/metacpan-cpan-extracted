# $Id: Makefile.PL,v 1.6 2000/03/02 20:12:23 ian Exp $

# Change Log:
# $Log: Makefile.PL,v $
# Revision 1.6  2000/03/02 20:12:23  ian
# Version 0.05 release
#
# Internally documented _report_or_set_or_delete and _generic_list
# Now deletes the users and/or groups hashes if they become empty.
#
# Make clean code improved
#
# Revision 1.5  2000/02/18 21:58:43  ian
# Changes now automatically updated via cvs2cl when makedist is run.
# After removing Changes from the repository, I'm going to make this
# version 0.03.
#
# Revision 1.4  2000/02/07 01:26:54  iroberts
# * Added Id and Log strings to all files
# * Now EXPORTs instead of EXPORT_OKing setfacl and getfacl
# * make clean now removes test-acl-file and test-acl-dir
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

unless ($^O eq 'solaris')
{
    die "Silly Rabit!  Solaris::ACL can only be built in Solaris!\n";
}

sub MY::clean
{
    package MY; # so that "SUPER" works right
    my $inherited = shift->SUPER::clean(@_);
    $inherited .= <<EOF;
	rm -f test-acl-file
	rm -rf test-acl-dir
EOF
    $inherited;
}

sub MY::dist_dir
{
    package MY; # so that "SUPER" works right

    my $inherited = shift->SUPER::dist_dir(@_);

    if(-d "CVS")
    {
	$inherited =~ s/(\n(\w+)\s*:)/$1 changelog/;
    }
    $inherited;
}

sub MY::postamble
{
    # If under CVS, use cvs2cl to generate Changes; available at
    # http://www.red-bean.com/~kfogel/cvs2cl.shtml

    "\nchangelog:\n\tcvs2cl -f Changes\n";
}

WriteMakefile(
    'NAME'	=> 'Solaris::ACL',
    'VERSION_FROM' => 'ACL.pm', # finds $VERSION
    'LIBS'	=> ['-lsec'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other'
);
