
# Module makefile for Mutex (using ExtUtils::MakeMaker)

use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
   ABSTRACT => 'Various locking implementations supporting processes and threads',
   AUTHOR   => 'Mario E. Roy <marioeroy AT gmail DOT com>',
   NAME     => 'Mutex',
   VERSION  => '1.005',

   NO_META  => 1,

   PREREQ_PM => {
      'base'     => 0,
      'strict'   => 0,
      'warnings' => 0,
      'Carp'     => 0,
      'Fcntl'    => 0,
      'Socket'   => 0
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
            'bugtracker' => 'https://github.com/marioroy/mutex-perl/issues',
            'homepage'   => 'https://github.com/marioroy/mutex-perl',
            'license'    => 'http://dev.perl.org/licenses/',
            'repository' => 'https://github.com/marioroy/mutex-perl.git'
         },
         'provides' => {
            'Mutex' => {
               'file'    => 'lib/Mutex.pm',
               'version' => '1.005'
            },
            'Mutex::Channel' => {
               'file'    => 'lib/Mutex/Channel.pm',
               'version' => '1.005'
            },
            'Mutex::Flock' => {
               'file'    => 'lib/Mutex/Flock.pm',
               'version' => '1.005'
            },
            'Mutex::Util' => {
               'file'    => 'lib/Mutex/Util.pm',
               'version' => '1.005'
            }
         }
      } ) : () ),

   (( eval { ExtUtils::MakeMaker->VERSION(6.48) } ) ?
      ( MIN_PERL_VERSION => 5.008 ) : () ),

   INSTALLDIRS => ( ($] < 5.011) ? 'perl' : 'site' )
);

