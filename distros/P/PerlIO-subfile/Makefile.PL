require 5.008; # Stop perl 5.005 or earler barfing on the v string
use ExtUtils::MakeMaker;
use Config;

unless ($Config{useperlio} eq 'define' and
	(defined($Config{usesfio}) ? $Config{usesfio} : 'false') eq 'false') {
  die <<BARF;
You need perl 5.8.0 or later, configured to use perlio (and not to use sfio)
BARF
}
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PerlIO::subfile',
    'VERSION_FROM'	=> 'subfile.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'subfile.pm', # retrieve abstract from module
    AUTHOR     => 'Nicholas Clark <nick@ccl4.org>',
    'LIBS'		=> [''], # e.g., '-lm'
#    'DEFINE'		=> '-Wall -DDEBUG_LAYERSUBFILE',
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
