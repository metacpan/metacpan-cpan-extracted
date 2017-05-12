use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Net::GPSD::Server::Fake},
  VERSION_FROM => q{lib/Net/GPSD/Server/Fake.pm},
  PREREQ_PM => {
                 strict               => 0,
                 vars                 => 0,
                 IO::Socket::INET     => 0,
                 Time::HiRes          => 0,
                 Geo::Functions       => 0.05,
                 Geo::Forward         => 0.09,
                 Net::GPSD::Point     => 0.35,
                 Net::GPSD::Satellite => 0.30,
                 GPS::SpaceTrack      => 0.11,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/Net/GPSD/Server/Fake.pm',
                 ) : ()
               ),
             );
