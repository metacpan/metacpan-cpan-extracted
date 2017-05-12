
#
# PCGI Makefile maker
#

use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'PCGI',
  VERSION_FROM   => 'lib/PCGI.pm',
  ABSTRACT_FROM  => 'lib/PCGI.pm',
  PREREQ_PM      => { 'Stream::Reader' => '0.09' },
  AUTHOR         => 'Andrian Zubko aka Ondr, <ondr@cpan.org>'
);
