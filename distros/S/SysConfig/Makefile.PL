use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "SysConfig",
              DISTNAME => "SysConfig",
              VERSION_FROM => 'lib/SysConfig.pm',
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
             );

