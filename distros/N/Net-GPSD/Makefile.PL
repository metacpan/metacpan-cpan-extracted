use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Net::GPSD},
  VERSION_FROM => 'lib/Net/GPSD.pm',
  ABSTRACT_FROM=> 'lib/Net/GPSD.pm',
  PREREQ_PM => {
                 'strict'             => 0,
                 'warnings'           => 0,
                 'Geo::Forward'       => 0.09,
                 'Geo::Inverse'       => 0.02,
                 'Geo::Functions'     => 0.06,
                 'IO::Socket::INET'   => 0,
                 'LWP::UserAgent'     => 0,
                 'GPS::OID'           => 0,
               },
             );
