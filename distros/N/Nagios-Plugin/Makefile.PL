die "This is a tombstone release, not an installable distribution\n"
  if -e 'META.yml';

use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
  NAME => 'Nagios::Plugin',
  VERSION_FROM => 'lib/Nagios/Plugin.pm'
);
