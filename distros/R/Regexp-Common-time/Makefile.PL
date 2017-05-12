use strict;
use warnings;

use ExtUtils::MakeMaker 6.5503;
WriteMakefile(
    NAME              => 'Regexp::Common::time',
    VERSION_FROM      => 'lib/Regexp/Common/time.pm',
    LICENSE           => 'unrestricted',
    BUILD_REQUIRES    => {
     'Test::More'     =>  '0.40',
    },
    PREREQ_PM         => {
     'Regexp::Common' =>  0,
     'POSIX'          =>  0,
    },
    PL_FILES          => {},
    ABSTRACT_FROM     => 'lib/Regexp/Common/time.pm',
    AUTHOR            => 'Eric J. Roode <eroode@barrack.com>',
    META_MERGE        => {
      "meta-spec" => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/szabgab/Regexp-Common-time.git',
          web => 'https://github.com/szabgab/Regexp-Common-time',
       },
     },
   },
);
