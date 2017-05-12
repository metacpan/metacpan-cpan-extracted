require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'SHA',
    'VERSION_FROM' => 'SHA.pm',
    'PREREQ_PM'    => { 'Digest::SHA1' => 1.00, },
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
