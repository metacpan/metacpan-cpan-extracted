#!perl -w
#                              -*- Mode: Perl -*- 
# $Basename$
# $Revision$
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Feb 25 10:25:48 2001

use ExtUtils::MakeMaker;

my @args;
my @libs = qw(-lpvm3 -lgpvm3);
if ($ENV{PVM_ROOT}) {
  # This should be the case, but is not necessary on Debian systems
  push @args, ('INC'       => '-I$(PVM_ROOT)/include');
  unshift @libs, "-L$ENV{PVM_ROOT}/lib/$ENV{PVM_ARCH}";
}
if ($^O eq "solaris") {
  push @libs, qw(-lsocket -lnsl);
}
push @args, ('LIBS', "@libs");

WriteMakefile
  (
   'NAME'	  => 'Parallel::Pvm',
   'VERSION_FROM' => 'Pvm.pm',
   'dist'         => {COMPRESS => "gzip", SUFFIX => "gz"},
   @args
);
