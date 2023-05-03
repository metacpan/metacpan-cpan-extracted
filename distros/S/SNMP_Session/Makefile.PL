use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'      => 'SNMP_Session',
	      'VERSION_FROM' => 'lib/SNMP_Session.pm', # finds $VERSION
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
	      );
