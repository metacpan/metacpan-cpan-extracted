use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::AssetPack::Che',
    AUTHOR           => q{Михаил Че (Mikhail Che) <mche<-on->cpan.org>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/AssetPack/Che.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/AssetPack/Che.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious::Plugin::AssetPack'              => '2.02',
        'HTML::Packer'=> '2.03',
        'IO::Compress::Gzip '=> '2.0',
        'CSS::Minifier::XS'	=> '0.09',
        'CSS::Sass'     =>  '3.0',
        'JavaScript::Minifier::XS'     => '0.1',
    },
      META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
          repository => {
            type => 'git',
            url => 'git://github.com/mche/Mojolicious-Plugin-AssetPack-Che.git',
            web => 'https://github.com/mche/Mojolicious-Plugin-AssetPack-Che',
          },
        },
      },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #clean => { FILES => 'Mojolicious-Plugin-AssetPack-Che-*' },
);
