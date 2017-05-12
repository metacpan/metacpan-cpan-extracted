use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Perlbal::Plugin::TrustHeader',
  AUTHOR        => 'Graham Barr <gbarr@pobox.com>',
  VERSION_FROM  => 'lib/Perlbal/Plugin/TrustHeader.pm',
  ABSTRACT_FROM => 'lib/Perlbal/Plugin/TrustHeader.pm',
  PREREQ_PM     => {                                      ##
    'Perlbal'      => 0,
    'Net::Netmask' => 0,
  },
);

