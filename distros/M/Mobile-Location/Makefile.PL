use 5.006;

use ExtUtils::MakeMaker;

my $module = 'Location.pm';

WriteMakefile(
              'NAME'         => 'Mobile::Location',
              'VERSION_FROM' => $module,
              'PREREQ_PM'    => { 
                                  'Devel::Scooby'   => 4.07,
                                  'Crypt::RSA'      => 1.50,
                                  'HTTP::Daemon'    => 1.26,
                                  'HTTP::Status'    => 1.26,
                                  'IO::Socket'      => 0,
                                  'Socket'          => 0,
                                  'Sys::Hostname'   => 0,
                                  'POSIX'           => 0,
                                  'constant'        => 0
                                },
             );
