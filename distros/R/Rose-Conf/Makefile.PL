require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Rose::Conf',
              PMLIBDIRS    => [ 'lib' ],
              VERSION_FROM => 'lib/Rose/Conf.pm',
              PREREQ_PM =>
              {
                'Rose::Object' => 0,
                'Tie::Hash'    => 0,
                'File::Spec'   => 0,
              });

