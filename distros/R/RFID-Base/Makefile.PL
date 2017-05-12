use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'RFID::Base',
	      VERSION_FROM    => 'lib/RFID/Reader.pm',
	      PREREQ_PM       => {
		Carp               => 0,
                Exporter           => 0,
 	        warnings           => 0,
		constant           => 0,
		Scalar::Util       => 0,
		IO::Handle         => 0,
		IO::Socket         => 0,
		IO::Socket::INET   => 0,
		Scalar::Util       => 0,
		Test::More         => 0,
		Fcntl              => 0,
	      }
	    );
