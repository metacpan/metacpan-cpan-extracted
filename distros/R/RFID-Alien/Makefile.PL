use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'RFID::Alien',
	      VERSION_FROM    => 'lib/RFID/Alien/Reader.pm',
	      PREREQ_PM       => {
		RFID::Tag              => 0.002,
		RFID::EPC::Tag         => 0.002,
		RFID::Reader           => 0.002,
		RFID::Reader::Serial   => 0.002,
		RFID::Reader::TestBase => 0.002,
		RFID::Reader::TCP      => 0.002,
	        POSIX                  => 0,
		Time::Local            => 0,
		Carp                   => 0,
                Exporter               => 0,
 	        warnings               => 0,
		constant               => 0,
	      },
	      );
