#!/usr/bin/perl -w

use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
  NAME => 'POE::Filter::RecDescent',
  VERSION_FROM => 'RecDescent.pm',
  PREREQ_PM => { POE => 0.27, 'Parse::RecDescent' => 0 },
);
