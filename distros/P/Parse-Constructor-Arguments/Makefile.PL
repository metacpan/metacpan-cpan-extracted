
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Parse-Constructor-Arguments',
  NAME      => 'Parse::Constructor::Arguments',
  AUTHOR    => 'Nicholas\ Perez\ \<nperez\@cpan\.org\>',
  ABSTRACT  => 'A PPI based module for parsing Moose-style constructor arguments',
  VERSION   => '0.091570',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "PPI" => '1.203',
    "Test::Exception" => '0.27',
    "MooseX::Types" => '0.10',
    "Moose" => '0.79',
  },
);
