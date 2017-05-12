
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

unless ($] >= 5.004) {
    print <<"EOF";
               *** REALLY BIG FAT FATAL ERROR ***

    Net::AIM requires Perl version 5.004 or higher. Please complain
    to your system administrator until she installs it. Sorry...

EOF

    exit 1;
}

WriteMakefile(
	      'NAME'  => 'Net::AIM',
	      'PM'    =>  {
		  'AIM.pm'        => '$(INST_LIBDIR)/AIM.pm',
		  'AIM/Connection.pm' => '$(INST_LIBDIR)/AIM/Connection.pm',
		  'AIM/Event.pm'      => '$(INST_LIBDIR)/AIM/Event.pm',
	      },
              'PREREQ_PM' => {
                  'IO::Select'    => 0,
                  'Carp'          => 0,
                  'Socket'        => 0,
                  'IO::File'      => 0,
                  'IO::Socket'    => 0,
                  'Sys::Hostname' => 0,
              },
	      'VERSION_FROM' => 'AIM.pm', # finds $VERSION
              'dist' => { 'COMPRESS' => 'gzip --best' },
);
