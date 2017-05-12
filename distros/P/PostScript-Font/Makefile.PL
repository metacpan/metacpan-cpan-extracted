# Makefile.PL -- Makefile for PostScript::Fonts
# Author          : Johan Vromans
# Created On      : Mon Feb  8 11:46:56 1999
# Last Modified By: Johan Vromans
# Last Modified On: Sat Dec 27 21:32:18 2014
# Update Count    : 102
# Status          : Stable

# Verify perl version.
require 5.000;
use Config;

use ExtUtils::MakeMaker;

my @scripts = qw(fontsampler font2pfa font2pfb ttfwrapper);
my $usrbin = "/usr/bin";
my $installscript = $Config{installscript};

print STDERR <<EOD unless $installscript eq $usrbin;

WARNING: This Makefile will install user accessible scripts.
The location for these scripts is $installscript.
You may consider to pass INSTALLSCRIPT=$usrbin (or some other
convenient location) to "make install".

EOD

eval {
    require Font::TTF::Font;
};
if ( $@ ) {
    print STDERR <<EOD;

NOTICE: This package handles PostScript fonts. It can also
handle TrueType fonts, if you install the Font::TTF package
from CPAN.

URL: http://search.cpan.org/search?query=Font::TTF&mode=dist

EOD
}

WriteMakefile
  (
   NAME         => 'PostScript::Font',
   ($] >= 5.005) ?
   ( AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
     ABSTRACT	=> 'Modules to get info for/from PostScript fonts' ) : (),
   VERSION      => "1.10.03",
   PREREQ_PM	=> { 'Getopt::Long' => 2.00, 'IO' => 0 },
   EXE_FILES    => [ map { "script/$_" } @scripts ],
   # *.pm files will be picked up automatically from ./lib
 );
