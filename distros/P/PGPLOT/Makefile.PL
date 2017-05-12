
require 5.003;
use lib ".";
use ExtUtils::MakeMaker;

BEGIN {
eval 'use blib "../ExtUtils";' # For KGB development
if -e "../ExtUtils";
}

use ExtUtils::F77; # This should work most of the time

# Examples of how to explicitly override default automatic choice
# of OS and compiler (currently commented out):

#use ExtUtils::F77 qw(solaris); 
#use ExtUtils::F77 qw(generic g77); 

use Config;
use IO::File;

use strict;

# use command line KEY=VALUE to override defaults.  VALUES are comma
# separated lists

my %Arg = ( 
	   # X11 library directories
	   XDIR => '/usr/openwin/lib,/usr/X11/lib,/usr/X11R6/lib',

	   # X11 libraries
	   XLIB => 'X11',


	   # where cpgplot.h should be
	   IDIR  => $ENV{PGPLOT_DIR} || '/usr/include,/usr/local/pgplot',

	   # where libpgplot.a should be
	   LDIR  => $ENV{PGPLOT_DIR} || '/usr/lib',

	   # extra libraries and directories
	   EXLIB => 'png',
	   EXDIR => '/usr/local/lib',
	  );


my @NARGV;
while( $_ = shift @ARGV )
{
  if ( /^([\S]+)=(.+)/ && exists $Arg{$1} )
  {
    $Arg{$1} = $2;
  }
  else
  {
    push @NARGV, $_;
  }
}
@ARGV = @NARGV;

my $LIBDIRS = join(' ', map {  "-L$_" }
		   map { split( ',', $_ ) }
		   @Arg{qw/ XDIR LDIR EXDIR /}
		  );

my $LIBS = join(' ', map { "-l$_" }
		qw/ cpgplot pgplot /,
		map { split( ',', $_ ) } @Arg{qw/ XLIB EXLIB /}
	       );

my $IDIRS = join( ' ', map { "-I$_" } split( ',', $Arg{IDIR} ) );

#
# Usage:
#   $needed_libs = find_required_driver_libs($dir);
#
# Aim:
#   Parse the drivers.list file to find out what extra libraries
#   are needed by the module. The file is assumed to be in
#   the directory $dir. If the file can not be read then
#   "" is returned rather than exiting with an error.
#
#   The return value is a string like "-lpng -laquaterm", which
#   can be "".
#
#   This is only used in the OS-X case. It is not currently guaranteed
#   to be complete since I have not made a complete study of the
#   drivers.
#
sub find_required_driver_libs ($) {
    my $indir = shift;
    my $infile = "${indir}/drivers.list";

    my $retval = "";

    my $fh = IO::File->new( "< $infile" )
	or return $retval;

    # known library requirements
    #
    my %libs = ( 
	'PNDRIV' => 'png',
	'AQDRIV' => 'aquaterm',
    );

    while (<$fh>) {
	next if /^\s*$/ or /^!/;  # /; (comment is to un-confuse emacs highlighting)
	chomp;
	my @words = split;
	if ( exists $libs{$words[0]} ) {
	    $retval .= " -l" . $libs{$words[0]};
	    delete $libs{$words[0]}; # since the driver can appear multiple times in drivers.list
	}
    }
    $fh->close;

    return $retval;

} # sub: find_required_driver_libs()

# What os are we using?
#
my $is_vms   = $^O eq "VMS";
my $is_osx   = $^O eq "darwin";
my $is_win32 = $^O =~ /mswin32/i;

# Move the logic out of the WriteMakefile statement to make it a
# bit easier to follow. We use the %items hash to store key,value
# pairs that will be used in the WriteMakefile call. Note that
# some key settings are platform specific.
#
my %items;

$items{DEFINE} = "-DNO_TRAILING_USCORE"
    unless ExtUtils::F77->trail_;

$items{DLEXT} = "xs.dll" if $is_win32;

if ( $is_vms ) {
    $items{INC}  = 'pgplot_dir:';
    $items{LIBS} = 'pgplot_dir:cpgplot.olb';
} else {

    $items{INC} = $IDIRS;

    $items{OBJECT} = '$(BASEEXT)$(OBJ_EXT) pgplot_tmp/libcpgplot.a ' .
	'pgplot_tmp/libpgplot.a'
	if -d 'pgplot_tmp';

    $items{LIBS} = [ join( ' ', $LIBDIRS, $LIBS, ExtUtils::F77->runtime ) ];

    # This is not ideal since it assumes that:
    #    objc is required
    #    the logic in find_required_driver_libs() is correct
    #    the libraries are located either in a location pointed to by LDFLAGS
    #       or in /sw/lib
    #
    if ($is_osx) {
	my $pgplot_dir = defined $ENV{PGPLOT_DIR} ? $ENV{PGPLOT_DIR} : "/usr/lib";
	my $dir = -d 'pgplot_tmp' ? 'pgplot_tmp' : $pgplot_dir;
	$items{LIBS}[0] .= " -lobjc " .
	    (defined $ENV{LDFLAGS} ? $ENV{LDFLAGS} : "-L/sw/lib") .
	    find_required_driver_libs($pgplot_dir);
    }

    # The following is needed for PGPLOT compiled on OS-X, at least
    # for both the version used from FINK and a hand-compiled version.
    #
    $items{LDDLFLAGS} = "$Config{lddlflags} -Wl,-framework -Wl,Foundation"
	if $is_osx;
 
    # Nasty hack to build only i386/x86_64 only instead of a Universal binary on OS X
    # I put this in to avoid an error if linking with the pgplot libs in 
    # SciKarl (2.4.6 and above). Hope one day to remove this.
    # - Karl Glazebrook
    if ($is_osx) {
       
       $items{CCFLAGS} = $Config{ccflags};
       $items{LDFLAGS} = $Config{ldflags};
       $items{LDDLFLAGS} = $Config{lddlflags};
       
       # Karl - now figure out automagically WHICH binary arch
       # to build for and change the various flags
       
       mac_universal( \$items{CCFLAGS}, \$items{LDFLAGS}, \$items{LDDLFLAGS});
       print "TEST $items{CCFLAGS}\n";
       print "TEST $items{LDFLAGS}\n";
       print "TEST $items{LDDLFLAGS}\n";

  
    }   

}

WriteMakefile(
    'NAME'	=> 'PGPLOT',
    'PREREQ_PM' => { 'ExtUtils::F77' => 1.13 },
    'VERSION_FROM'	=> 'PGPLOT.pm',
    'dist'      => { COMPRESS=>"gzip", SUFFIX=>"gz" },
    'depend'    => { '$(OBJECT)' => q[pgfun.c arrays.c PGPLOT.c]},
    %items
);


# This subroutine is a nasty hack to modify OS X compile strings
# to only build for a single architectutre
# Karl Glazebrook (Dec 2010);

sub mac_universal { # Note args passed as refs otherwise don't get modified!
	my @args = @_;
	my $s = ${$args[0]};
	
	my $count=0;
	
	# Do matching against various combinations of 
	# -arch ppc -arch i386 -arch x86_64
	# Prefer i386 then prefer x86_64.
	
	
	$count++ while $s =~ /-arch\s\S+/g;	
	return  if $count <2;  # Do nothing
	
	print "\nMac OS X with multiple architecture perl detected...\n";
	print "Trying to figure out which arch to build for...\n";
	
	# Figure out which single architecture to build for
	# when we have more than one
	
	my $singlearch = 'x86_64';
	$singlearch = 'i386' if $s=~/-arch\s+i386/ & $s=~/-arch\s+ppc/;
	$singlearch = 'x86_64' if $s=~/-arch\s+x86_64/;
		
	# If we can find pgplot's xwindow server try and match the arch it is built for
	
	my $pgarch = '';
	my $f1 =  `which pgxwin_server`; chomp $f1; # Find in path
	$f1 = '/usr/local/bin/pgxwin_server' if !-e $f1; # Backuo choice
	
	if (-e $f1) {
	    print "- Found $f1, trying to determine binary type\n";
	    my $exe = `file $f1`; chomp $exe;
	    $pgarch = (split(' ',$exe))[-1];
	}
	 if ($pgarch ne '') {
	    print "- Found binary type $pgarch\n";
	    $singlearch = $pgarch;
	}
	
	print "- Building for single architecture -arch $singlearch\n";
	# Now substitute the single arch for the multiple pnes
	
	my $t;
	for $t (@args) {
	   $$t =~ s/-arch\s\S+/TESTMARKER/; # Temp mark first occurence
   	   $$t =~ s/-arch\s\S+/ /g; # Remove all -arch's
	   $$t =~ s/TESTMARKER/-arch $singlearch/; # Put one back
	   print "\nRESULT: $$t\n";
	}
	
}