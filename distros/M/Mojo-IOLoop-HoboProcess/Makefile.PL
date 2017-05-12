
# Module makefile for Mojo::IOLoop::HoboProcess (using ExtUtils::MakeMaker)

use 5.010001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
   ABSTRACT => 'Like Mojo::IOLoop::Subprocess, spawns subprocesses with MCE::Hobo instead',
   AUTHOR   => 'Mario E. Roy <marioeroy AT gmail DOT com>',
   NAME     => 'Mojo::IOLoop::HoboProcess',
   VERSION  => '0.005',

   NO_META  => 1,

   PREREQ_PM => {
      'strict'       => 0,
      'warnings'     => 0,
      'Carp'         => 0,
      'MCE::Shared'  => 1.817,
      'Mojolicious'  => 7.07,
      'Scalar::Util' => 0,
      'Socket'       => 0
   },

   ((!eval { ExtUtils::MakeMaker->VERSION(6.25) } ) ?
      ( PL_FILES => {} ) : () ),

   (( eval { ExtUtils::MakeMaker->VERSION(6.31) } ) ?
      ( LICENSE => 'perl' ) : () ),

   (( eval { ExtUtils::MakeMaker->VERSION(6.46) } ) ?
      ( META_MERGE => {
         'build_requires' => {
            'ExtUtils::MakeMaker' => 0,
            'Test::More'          => 0.88
         },
         'resources' => {
            'bugtracker' => 'https://github.com/marioroy/Mojo-IOLoop-HoboProcess/issues',
            'homepage'   => 'https://github.com/marioroy/Mojo-IOLoop-HoboProcess',
            'license'    => 'http://dev.perl.org/licenses/',
            'repository' => 'https://github.com/marioroy/Mojo-IOLoop-HoboProcess.git'
         },
         'provides' => {
            'Mojo::IOLoop::HoboProcess' => {
               'file'    => 'lib/Mojo/IOLoop/HoboProcess.pm',
               'version' => '0.005'
            }
         }
      } ) : () ),

   (( eval { ExtUtils::MakeMaker->VERSION(6.48) } ) ?
      ( MIN_PERL_VERSION => 5.010001 ) : () ),

   INSTALLDIRS => ( ($] < 5.011) ? 'perl' : 'site' )
);

