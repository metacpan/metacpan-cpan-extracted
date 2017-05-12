require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Rose',
              PMLIBDIRS    => [ 'lib' ],
              VERSION_FROM => 'lib/Rose.pm',
              ($^O =~ /darwin/i ?
               (dist => { DIST_CP => 'cp' }) : ()), # Avoid Mac OS X ._* files
              PREREQ_PM =>
              {
                'Test::More'          => 0,
                'Rose::Object'        => 0,
                'Rose::DB'            => 0,
                'Rose::DB::Object'    => 0,
                'Rose::DateTime'      => 0,
                'Rose::URI'           => 0,
                'Rose::HTML::Objects' => 0,
              });
