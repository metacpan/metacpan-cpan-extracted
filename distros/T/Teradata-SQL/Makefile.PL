use ExtUtils::MakeMaker;

if ($^O =~ /mswin/i) {
   $my_libs = "-lwincli32";
} else {
   # If CLI is not installed, warn.
   unless (-f "/usr/include/coptypes.h") {
      print "CLIv2 installation not found.\n";
   }

   $my_libs = "-lcliv2 -ltdusr -lnsl -lsocket";
}
 
WriteMakefile(
    'NAME'              => 'Teradata::SQL',
    'VERSION_FROM'      => 'SQL.pm', # finds $VERSION
    'PREREQ_PM'         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( AUTHOR     => 'Geoffrey Rommel <GROMMEL@cpan.org>',
        ABSTRACT   => 'Perl interface to Teradata SQL (CLIv2)') : ()),
    'LIBS'              => [$my_libs],
    'DEFINE'            => '-DNO_CLIV2_ERROR_T', # e.g., '-DHAVE_SOMETHING'
    'C'                 => ['SQL.c', 'tdsql.c'] ,
    'INC'               => '-I.', # e.g., '-I/usr/include/other'
    'OBJECT'            => '$(O_FILES) tdsql.o',
    'LDFROM'            => '$(O_FILES)',
);

