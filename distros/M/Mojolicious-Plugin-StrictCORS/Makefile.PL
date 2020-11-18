#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => "Mojolicious::Plugin::StrictCORS",
  VERSION_FROM  => "lib/Mojolicious/Plugin/StrictCORS.pm",
  ABSTRACT      => "Strict CORS routes in your Mojolicious app",
  LICENSE       => 'artistic_2',
  AUTHOR        => "Dmitry Krutikov <monstar\@cpan.org>",
  META_MERGE    => {
    'meta-spec'   => { version => 2 },
    resources     => {
      bugtracker  => { web => 'https://github.com/bitnoize/mojolicious-plugin-strictcors/issues' },
      license     => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository  => {
        type  => 'git',
        url   => 'git://github.com/bitnoize/mojolicious-plugin-strictcors.git',
        web   => 'https://github.com/bitnoize/mojolicious-plugin-strictcors',
      },
    },
  },
  PREREQ_PM     => {
    'Mojolicious' => '8.12'
  },
  test => { TESTS => 't/*.t' }
);
