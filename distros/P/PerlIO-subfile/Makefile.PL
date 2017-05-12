require 5.007001; # Stop perl 5.005 or earler barfing on the v string
# require 5.7.1;
use ExtUtils::MakeMaker;
use Config;

unless ($Config{useperlio} eq 'define' and $Config{usesfio} eq 'false') {
  die <<BARF;
You need perl 5.7.1 or later, configured to use perlio (and not to use sfio)
Yes, this module is currently only suitable for the development branch of
perl

Note
  1: The features required for layers have only recently been added to
     development perl, so if your doesn't have the header perliol.h it's
     too old
  2: The perlio layers API has changed (at least once) between the initial
     version and 5.7.1, and may well change again. If so, it is quite
     possible that this module will fail to compile.
BARF
}
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PerlIO::subfile',
    'VERSION_FROM'	=> 'subfile.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'subfile.pm', # retrieve abstract from module
       AUTHOR     => 'Nicholas Clark <nick@talking.bollo.cx>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
#    'DEFINE'		=> '-Wall -DDEBUG_LAYERSUBFILE',
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
