use 5.016;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojo::Collection::XS',
  VERSION_FROM => 'lib/Mojo/Collection/XS.pm',
  ABSTRACT     => 'Fast XS subclass of Mojo::Collection with XS-based while',
  AUTHOR       => 'Achmad Yusri Afandi <yusrideb@cpan.org>',
  LICENSE      => 'artistic_2',

  PREREQ_PM => {Mojolicious => 0,},

  XS     => {'XS.xs' => 'XS.c'},
  OBJECT => '$(O_FILES)',

  META_MERGE => {
    no_index  => {directory              => ['test']},
    prereqs   => {runtime                => {requires => {perl => '5.016'}}},
    provides  => {'Mojo::Collection::XS' => {file     => 'lib/Mojo/Collection/XS.pm', version => '0.2',},},
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/CellBIS/mojo-collection-xs.git',
        web  => 'https://github.com/CellBIS/mojo-collection-xs',
      },
      bugtracker => {web => 'https://github.com/CellBIS/mojo-collection-xs/issues',},
    },
  },

  META_ADD => {
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/CellBIS/mojo-collection-xs.git',
        web  => 'https://github.com/CellBIS/mojo-collection-xs',
      },
    },
  },
);
