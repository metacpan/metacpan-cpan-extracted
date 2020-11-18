#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Mojolicious::Plugin::MoreHelpers',
  VERSION_FROM  => 'lib/Mojolicious/Plugin/MoreHelpers.pm',
  ABSTRACT      => 'More helpers lacking in Mojolicious',
  LICENSE       => 'artistic_2',
  AUTHOR        => 'Dmitry Krutikov <monstar@cpan.org>',
  META_MERGE    => {
    'meta-spec'   => { version => 2 },
    resources     => {
      bugtracker  => { web => 'https://github.com/bitnoize/mojolicious-plugin-morehelpers/issues' },
      license     => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository  => {
        type  => 'git',
        url   => 'git://github.com/bitnoize/mojolicious-plugin-morehelpers.git',
        web   => 'https://github.com/bitnoize/mojolicious-plugin-morehelpers',
      },
    },
  },
  PREREQ_PM     => {
    "Mojolicious" => '8.12'
  },
  test => { TESTS => 't/*.t' }
);
