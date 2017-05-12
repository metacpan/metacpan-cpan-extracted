use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "RedHat-Kickstart",
              DISTNAME => "RedHat-Kickstart",
              VERSION_FROM => 'lib/RedHat/SysConfig.pm',
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
             );

