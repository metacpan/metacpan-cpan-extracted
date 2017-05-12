
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Proc-CPUUsage',
  NAME      => 'Proc::CPUUsage',
  AUTHOR    => "Pedro\ Melo",
  ABSTRACT  => "measures\ the\ percentage\ of\ CPU\ the\ current\ process\ is\ using",
  VERSION   => '1.001',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.92',
    "Time::HiRes" => '0',
    "BSD::Resource" => '0',
  },
  test => {TESTS => 't/*.t'}
);

