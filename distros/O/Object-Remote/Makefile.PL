use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Object::Remote',
  VERSION_FROM => 'lib/Object/Remote.pm',
  PREREQ_PM => {
    Moo => 1.006,
    'Module::Runtime' => 0,
    'JSON::PP' => 0,
    'Future' => 0.29,
    'MRO::Compat' => 0, # required to fatpack Moo
    'Class::C3' => 0, # required to fatpack Moo
    'String::ShellQuote' => 0, # required for ssh argument manipulation
    'Log::Contextual' => 0.005000,
    strictures => 2,
  },
  EXE_FILES => [
    'bin/object-remote-node',
    'bin/object-remote-slave',
    'bin/remoterepl',
  ],
);
