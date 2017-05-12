use ExtUtils::MakeMaker;

WriteMakefile(
	            NAME            => 'RFID::ISO15693::Tag',
	            VERSION_FROM    => 'lib/RFID/ISO15693/Tag.pm',
	            PREREQ_PM       => {
					RFID::Tag            => 0.002,
					Carp                   => 0,
					Exporter               => 0,
				        warnings               => 0,
					constant               => 0,
					      },
	            );
