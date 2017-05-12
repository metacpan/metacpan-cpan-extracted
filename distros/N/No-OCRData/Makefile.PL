require 5.002;
use ExtUtils::MakeMaker;

WriteMakefile(
        NAME     => 'No',
        VERSION  => '0.9',
        DISTNAME => 'No-OCRData',
        dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
