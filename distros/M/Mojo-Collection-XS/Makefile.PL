use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojo::Collection::XS',
  VERSION_FROM => 'lib/Mojo/Collection/XS.pm',
  ABSTRACT     => 'Fast XS subclass of Mojo::Collection with XS-based while',
  AUTHOR       => 'Achmad Yusri Afandi <yusrideb@cpan.org>',
  LICENSE      => 'perl',

  PREREQ_PM => {Mojolicious => 0},

  # XS support
  XS     => {'XS.xs' => 'XS.c'},
  OBJECT => '$(O_FILES)',

  # MetaCPAN information
  META_MERGE => {
    resources => {
      repository => {
        url  => 'https://github.com/CellBIS/mojo-collection-xs',
        web  => 'https://github.com/CellBIS/mojo-collection-xs',
        type => 'git',
      },
      bugtracker => {web => 'https://github.com/CellBIS/mojo-collection-xs/issues',},
    },
    no_index => {directory => ['test'],},
  },
);
