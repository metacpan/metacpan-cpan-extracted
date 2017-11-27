#!/usr/bin/env perl

use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'MooX::EventHandler',
  AUTHOR         => 'Matthew King (cpan:CHOHAG) <chohag@jtan.com>',
  ABSTRACT_FROM  => 'lib/MooX/EventHandler.pm',
  VERSION_FROM   => 'lib/MooX/EventHandler.pm',
  LICENSE        => 'wtfpl_2',
  PREREQ_PM      => {
    'perl'               => '5.006', # Probably; it's what Moo and strictures need.
    'Moo'                => '0',
    'strictures'         => '2',
  },
);
