use 5.006;

use strict;

use ExtUtils::MakeMaker;
use Config;

if ((not $ARGV[0]) or (not $ARGV[1]))
{
	print "Usage: perl Makefile.PL <path-to-sendmail-source> <path-to-sendmail-obj.dir>\n";
	print "(e.g. 'perl Makefile.PL ../sendmail ../sendmail/obj.FreeBSD.4.0-RELEASE.i386')\n";
	print "\n";
	exit;
}

if (not $Config{usethreads})
{
	print "To use this module, your perl interpreter must have been compiled with\n";
	print "\t-Dusethreads.\n";
	print "\n";
	exit;
}

my $SENDMAIL_PATH = MM->canonpath($ARGV[0]);
my $SENDMAIL_OBJ_PATH = MM->canonpath($ARGV[1]);

my $MILTER_LIB = MM->catdir($SENDMAIL_OBJ_PATH, "libmilter");
my $SMUTIL_LIB = MM->catdir($SENDMAIL_OBJ_PATH, "libsmutil");
my $SM_LIB = MM->catdir($SENDMAIL_OBJ_PATH, "libsm");
my $MILTER_INCLUDE = MM->catdir($SENDMAIL_PATH, "include");
my $SENDMAIL_INCLUDE = MM->catdir($SENDMAIL_PATH, "sendmail");

sub milter_configure
{
	my $hash_ref = {};
	my $libs;
	my $ccflags;

	# Standard milter libraries
	$libs = "-L$MILTER_LIB -L$SMUTIL_LIB -L$SM_LIB -lmilter -lsmutil -lsm";

	# POSIX threads support.
	if ($Config{libs} =~ /-lpthread/)
	{
		$libs .= " -lpthread";
	}
	else
	{
		$ccflags = '-pthread';
	}

	# Solaris 2.6 -lsocket -lnsl support.
	if ($Config{libs} =~ /-lsocket/)
	{
		$libs .= " -lsocket";
	}
	if ($Config{libs} =~ /-lnsl/)
	{
		$libs .= " -lnsl";
	}

	# Solaris and inet_aton / inet_pton functions.
	if (($^O eq 'solaris') && (not $Config{d_inetaton}))
	{
		$libs .= " -lresolv";
	}

	# Only set the CCFLAGS variable if there's something.
	if ($ccflags)
	{
		$hash_ref->{'CCFLAGS'} = $ccflags;
	}

	$hash_ref->{'LIBS'} = [ "$libs" ];

	return $hash_ref;
}

WriteMakefile(
    'NAME'		=> 'Sendmail::Milter',
    'VERSION_FROM'	=> 'Milter.pm',
    'CONFIGURE'		=> \&milter_configure,
    'OBJECT'		=> '$(BASEEXT)$(OBJ_EXT) intpools$(OBJ_EXT) callbacks$(OBJ_EXT)',
    'DEFINE'		=> '',
    'INC'		=> "-I$SENDMAIL_INCLUDE -I$MILTER_INCLUDE",
);

