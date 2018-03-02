use strict;
use warnings;

use ExtUtils::MakeMaker 6.5503;
WriteMakefile(
    NAME              => 'Regexp::Common::time',
    VERSION_FROM      => 'lib/Regexp/Common/time.pm',
    LICENSE           => 'unrestricted',
    MIN_PERL_VERSION  => 5.006,
    BUILD_REQUIRES    => {
     'Test::More'     =>  '0.40',
     'Modern::Perl'   =>  '0',
    },
    PREREQ_PM         => {
     'Regexp::Common' =>  0,
    },
    ABSTRACT_FROM     => 'lib/Regexp/Common/time.pm',
    AUTHOR            => 'Eric J. Roode <eroode@barrack.com>',
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean             => { FILES => 'Regexp-Common-time-*' },
    META_MERGE        => {
      "meta-spec" => { version => 2 },
      provides    => {
          'Regexp::Common::time' => { file => 'lib/Regexp/Common/time.pm', version => '0.16' },
      },
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/manwar/Regexp-Common-time.git',
          web => 'https://github.com/manwar/Regexp-Common-time',
       },
     },
   },
);
