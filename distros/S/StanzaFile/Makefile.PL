use ExtUtils::MakeMaker;

require 5.6.1 ;

WriteMakefile
   (NAME => "StanzaFile",
    VERSION_FROM => "StanzaFile.pm",
    PREREQ_PM => {'FileHandle' => 2.00},
    ($[ >= 5.005) ?
        (AUTHOR   => 'Dick Munroe (munroe@csworks.com)',
         ABSTRACT => 'Parse files organized as Stanzas') : (),
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'}
   );
