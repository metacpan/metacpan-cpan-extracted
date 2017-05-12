#!perl -w
use 5.008; # Stop perl 5.005 or earler barfing on the v string
# require 5.7.0;
use ExtUtils::MakeMaker;
use Config;

unless ($Config{useperlio} eq 'define' and
	(defined($Config{usesfio}) ? $Config{usesfio} : 'false') eq 'false') {
  die <<BARF;
You need perl 5.8.0 or later, configured to use perlio (and not to use sfio)
BARF
}

# OK. Is this worth it? For starters, it's somewhat potty as the "OS types" in
# RFC 1952 are actaully semi-muddled with FS types.

my $ostype;

if ($^O eq 'dos') {
  $ostype = 0;
} elsif ($^O eq 'amigaos') {
  $ostype = 1;
} elsif ($^O eq 'VMS') {
  $ostype = 2;
} elsif ($^O eq 'mint') {
  # Is this correct?
  $ostype = 5;
} elsif ($^O eq 'os2') {
  $ostype = 6;
} elsif ($^O eq 'MacOS') {
  $ostype = 7;
} elsif ($^O eq 'MSWin32' or $^O eq 'cygwin') {
  $ostype = 11;
} elsif ($^O eq 'RISCOS') {
  $ostype = 13;
} elsif ($Config{cppccsymbols} =~ /\sunix=/ or $^O eq 'darwin') {
  # Darwin is a BSD, but it has a somewhat borked gcc, so be sure to get it
  $ostype = 3;
} else {
  # Don't know.
  $ostype = ''
}

$ostype = "-DLAYERGZIP_DEFAULT_OS_TYPE=$ostype" if length $ostype;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PerlIO::gzip',
    'VERSION_FROM'	=> 'gzip.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM	=> 'gzip.pm', # retrieve abstract from module
    AUTHOR	=> 'Nicholas Clark <nwc10+perlio-gzip@colon.colondot.net>',
    'LIBS'		=> ['-lz'],
    'DEFINE'		=> $ostype,
    ((eval $ExtUtils::MakeMaker::VERSION > 6.30) ? (LICENSE => 'perl') : ()),
#    'DEFINE'		=> '-g -Wall -DDEBUG_LAYERGZIP',
);

# Check out Radioactive::Decay at http://belfast.pm.org/Modules/
# It might be more useful than this module :-)

__END__

OS types, from RFC 1952

                 0 - FAT filesystem (MS-DOS, OS/2, NT/Win32)
                 1 - Amiga
                 2 - VMS (or OpenVMS)
                 3 - Unix
                 4 - VM/CMS
                 5 - Atari TOS
                 6 - HPFS filesystem (OS/2, NT)
                 7 - Macintosh
                 8 - Z-System
                 9 - CP/M
                10 - TOPS-20
                11 - NTFS filesystem (NT)
                12 - QDOS
                13 - Acorn RISCOS
               255 - unknown
