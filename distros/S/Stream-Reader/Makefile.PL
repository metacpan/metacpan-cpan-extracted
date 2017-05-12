
#
# Stream::Reader Makefile maker
#

use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'Stream::Reader',
  VERSION_FROM   => 'lib/Stream/Reader.pm',
  ABSTRACT_FROM  => 'lib/Stream/Reader.pm',
  AUTHOR         => 'Andrian Zubko aka Ondr, <ondr@cpan.org>'
);
