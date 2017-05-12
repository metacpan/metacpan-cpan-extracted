#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Parse::CPAN::Packages',
    VERSION_FROM => 'lib/Parse/CPAN/Packages.pm',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    ABSTRACT     => 'Parse 02packages.details.txt.gz',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        map { $_ => 0 }
          qw(
          Archive::Peek
          Compress::Zlib
          CPAN::DistnameInfo
          File::Slurp
          Moo
          Path::Class
          PPI
          Test::InDistDir
          Test::More
          Type::Utils
          Types::Standard
          version
          )
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url =>
                    'https://github.com/wchristian/parse-cpan-packages.git',
                web => 'https://github.com/wchristian/parse-cpan-packages',
            },
        },
    },
);
