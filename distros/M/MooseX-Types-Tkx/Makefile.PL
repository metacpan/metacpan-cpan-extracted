use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
   NAME             => 'MooseX::Types::Tkx',
   AUTHOR           => 'Juergen von Brietzke <juergen.von.brietzke@t-online.de>',
   VERSION_FROM     => 'lib/MooseX/Types/Tkx.pm',
   ABSTRACT_FROM    => 'lib/MooseX/Types/Tkx.pm',
   PL_FILES         => {},
   MIN_PERL_VERSION => '5.012000',
   PREREQ_PM => {
      'perl'                 => 5.012000,
      'Scalar::Util'         => 0,
      'Modern::PBP::Perl'    => 1.200,
      'MooseX::Types'        => 0,
      'MooseX::Types::Moose' => 0,  
   },
   BUILD_REQUIRES => {
      'Test::More'          => 0,
      'Test::Pod'           => 1.14,
      'Test::Pod::Coverage' => 1.04,
   },
   dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean => { FILES => 'MooseX-Types-Tkx-*' },
);
