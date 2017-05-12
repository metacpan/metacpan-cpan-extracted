
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Net-Dropbox',
  NAME      => 'Net::Dropbox',
  AUTHOR    => 'sungo\ \<sungo\@sungo\.us\>',
  ABSTRACT  => 'Communicate\ with\ local\ Dropbox\ daemon',
  VERSION   => '1.091510',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'bsd') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "MooseX::StrictConstructor" => '0',
    "File::HomeDir" => '0',
    "Encode" => '0',
    "Moose" => '0',
  },
);
