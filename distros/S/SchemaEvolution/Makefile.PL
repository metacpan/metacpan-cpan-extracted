
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'SchemaEvolution',
  NAME      => 'SchemaEvolution',
  AUTHOR    => "Oliver\ Charles\ \<oliver\.g\.charles\@googlemail\.com\>",
  ABSTRACT  => "SchemaEvolution\ \-\ manage\ the\ evolution\ of\ a\ database\ with\ simple\ files",
  VERSION   => '0.03',
  EXE_FILES => [ qw(script/evolve.pl script/ChangeLog) ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => '') : ()),
  PREREQ_PM    => {
    "File::Find::Rule" => '0',
    "MooseX::Has::Sugar" => '0',
    "Try::Tiny" => '0',
    "MooseX::Getopt" => '0',
    "Path::Class" => '0',
    "Config::Tiny" => '0',
    "DBI" => '0',
    "File::Slurp" => '0',
    "Moose" => '0',
  },
  test => {TESTS => 't/*.t'}
);

