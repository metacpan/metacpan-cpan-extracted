use strict;
use warnings;

use ExtUtils::MakeMaker;
use utf8;

WriteMakefile(
    NAME             => 'Regexp::ERE'
  , MIN_PERL_VERSION => '5.008008'
  , VERSION_FROM     => 'lib/Regexp/ERE.pm'
  , ABSTRACT_FROM    => 'lib/Regexp/ERE.pm'
  , AUTHOR           => 'Loïc Jonas Etienne <loic.etienne@tech.swisssign.com>'
  , LICENSE          => 'artistic_2'
);
