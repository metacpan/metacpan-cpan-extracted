use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::SSH2::PublicKey',
    AUTHOR              => q{Nathan Marley <nathan.marley@gmail.com>},
    VERSION_FROM        => 'lib/Parse/SSH2/PublicKey.pm',
    ABSTRACT_FROM       => 'lib/Parse/SSH2/PublicKey.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'File::Temp' => 0,
        'File::Slurp' => 0,
    },
    PREREQ_PM => {
        'autodie' => 0,
        'Carp' => 0,
        'MIME::Base64' => 0,
        'Moo' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-SSH2-PublicKey-*' },
);
