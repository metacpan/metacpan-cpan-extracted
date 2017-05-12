use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'RFID::EPC',
	      VERSION_FROM    => 'lib/RFID/EPC/Tag.pm',
	      PREREQ_PM       => {
		RFID::Tag            => 0.002,
		Carp                 => 0,
                Exporter             => 0,
 	        warnings             => 0,
		constant             => 0,
	      },
	      );
