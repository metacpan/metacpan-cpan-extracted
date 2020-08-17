#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => "Mojolicious::Plugin::StrictCORS",
  VERSION_FROM  => "lib/Mojolicious/Plugin/StrictCORS.pm",
  ABSTRACT      => "Strict CORS routes in your Mojolicious app",
  LICENSE       => 'artistic_2',
  AUTHOR        => "Dmitry Krutikov <monstar\@cpan.org>",
  PREREQ_PM     => {
    'Mojolicious' => '8.12'
  },
  test => { TESTS => 't/*.t' }
);
