# -*- mode: Perl -*-

use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(NAME         => "SNMP::MIB::Compiler",
              VERSION_FROM => "lib/SNMP/MIB/Compiler.pm",
              dist         => { COMPRESS => "gzip", SUFFIX => "gz" },
	      PREREQ_PM    => { 'Data::Dumper'  => 0,
				'Data::Compare' => 0 },
	      clean        => { FILES => '*.bak *.old out/* ' .
				   'lib/*/*/*~ lib/*/*/*/*~' },
	      EXE_FILES    => [ qw(mibcompiler mibbrowser) ],
              );

sub MY::postamble {
'
sync-in:
	rsync -rv -e ssh nexus:~/reseaux/devel/mib/. .

sync-out:
	rsync -rv -e ssh . nexus:~/reseaux/devel/mib/.
';
}
