#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => "Mojolicious::Plugin::MultiLanguage",
  VERSION_FROM  => "lib/Mojolicious/Plugin/MultiLanguage.pm",
  ABSTRACT      => "Find available native language in your Mojolicious app",
  LICENSE       => 'artistic_2',
  AUTHOR        => "Dmitry Krutikov <monstar\@cpan.org>",
  PREREQ_PM     => {
    'HTTP::AcceptLanguage'  => '0.02',
    'Mojolicious'           => '8.12',
  },
  test => { TESTS => 't/*.t' }
);
