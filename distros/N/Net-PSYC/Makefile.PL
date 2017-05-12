
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      'NAME'  => 'Net::PSYC',
	      'PM'    =>  {
		  'PSYC.pm'        => '$(INST_LIBDIR)/PSYC.pm',
		  'PSYC/Circuit.pm' => '$(INST_LIBDIR)/PSYC/Circuit.pm',
		  'PSYC/Datagram.pm' => '$(INST_LIBDIR)/PSYC/Datagram.pm',
		  'PSYC/Event.pm' => '$(INST_LIBDIR)/PSYC/Event.pm',
		  'PSYC/State.pm' => '$(INST_LIBDIR)/PSYC/State.pm',
		  'PSYC/Hook.pm' => '$(INST_LIBDIR)/PSYC/Hook.pm',
		  'PSYC/Storage.pm' => '$(INST_LIBDIR)/PSYC/Storage.pm',
		  'PSYC/Client.pm' => '$(INST_LIBDIR)/PSYC/Client.pm',
		  'PSYC/FileShare.pm' => '$(INST_LIBDIR)/PSYC/FileShare.pm',

		  'PSYC/Event/Glib.pm' => '$(INST_LIBDIR)/PSYC/Event/Glib.pm',
		  'PSYC/Event/Event.pm' => '$(INST_LIBDIR)/PSYC/Event/Event.pm',
		  'PSYC/Event/IO_Select.pm' => '$(INST_LIBDIR)/PSYC/Event/IO_Select.pm',

		  'PSYC/Tie/AbbrevHash.pm' => '$(INST_LIBDIR)/PSYC/Tie/AbbrevHash.pm',
		  'PSYC/Tie/File.pm' => '$(INST_LIBDIR)/PSYC/Tie/File.pm',

		  'PSYC/MMP/Compress.pm' => '$(INST_LIBDIR)/PSYC/MMP/Compress.pm',
		  'PSYC/MMP/State.pm' => '$(INST_LIBDIR)/PSYC/MMP/State.pm',
	      },
	      'PREREQ_PRINT' => 1,
              'PREREQ_PM' => {
                  'Storable'		=> 0,
                  'Carp'		=> 0,
                  'Socket'		=> 0,
		  'Fcntl'		=> 0,
		  'bytes'		=> 0,
		  'base'		=> 0,
		  'strict'		=> 0,
                  'IO::Socket'		=> 0,
                  'Exporter'		=> 0,
              },
	      'VERSION_FROM' => 'PSYC.pm', # finds $VERSION
              'dist' => { 'COMPRESS' => 'gzip --best' },
);
