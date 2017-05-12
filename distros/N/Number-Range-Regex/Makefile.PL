use ExtUtils::MakeMaker;
#use Getopt::Long;

use strict;

do 'misc/handle-deprecated-cruft.pl';

WriteMakefile(
  'NAME'	=> 'Number::Range::Regex',
  'VERSION_FROM' => 'lib/Number/Range/Regex.pm', # finds $VERSION
  'PREREQ_PM' => { 'overload' => 0 },

  'dist'	=> { COMPRESS => 'gzip -9', SUFFIX => 'gz' },
);
