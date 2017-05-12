use strict;
use ExtUtils::MakeMaker;

eval { require 5.008 } or die <<EOD;
############
### RTF::HTMLConverter uses the unicode support which is
### not fully available before version 5.8.0 of perl.
### Please upgrade your perl before proceeding.
############
EOD

WriteMakefile(
    NAME                => 'RTF::HTMLConverter',
    VERSION_FROM        => 'HTMLConverter.pm',
    PREREQ_PM           => {
                             'Error'        => 0,
                             'Encode'       => 0,
                           },
);

