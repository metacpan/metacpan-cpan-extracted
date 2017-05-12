use 5.006;

use ExtUtils::MakeMaker;

my $module = 'Executive.pm';

WriteMakefile(
              'NAME'         => 'Mobile::Executive',
              'VERSION_FROM' => $module,
              'PREREQ_PM'    => { 
                                  'Devel::Scooby'    => 4.07,
                                  'Mobile::Location' => 4.01,
				  'Crypt::RSA'       => 1.50,
                                  'constant'         => 0,
                                  'File::Spec'       => 0
                                },
             );
