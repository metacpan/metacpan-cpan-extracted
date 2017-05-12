require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Rose::DateTime',
              PMLIBDIRS    => [ 'lib' ],
              VERSION_FROM => 'lib/Rose/DateTime.pm',
              ($^O =~ /darwin/i ?
               (dist => { DIST_CP => 'cp' }) : ()), # Avoid Mac OS X ._* files
              PREREQ_PM =>
              {
                'DateTime'     => 0,
                'Rose::Object' => 0.82,
              });
