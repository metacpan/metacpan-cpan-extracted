use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %RUN_DEPS = (
  'Set::Object' => 0,
  'MooX::Types::MooseLike' => 0.23,
);
my %BUILD_DEPS = (
  'Test::More'  => 0.96,
  'Test::Fatal' => 0.003,
);

WriteMakefile(
  NAME => 'MooX-Types-SetObject',
  VERSION_FROM => 'lib/MooX/Types/SetObject.pm',
  PREREQ_PM => {
    %RUN_DEPS,
  },
  BUILD_REQUIRES => {
    %BUILD_DEPS,
  },
  META_ADD => {
    resources => {
      repository  => 'git://github.com/mateu/MooX-Types-SetObject.git',
      bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Types-SetObject',
      IRC         => 'irc://irc.perl.org/#web-simple',
    },
  },
  LICENSE => 'perl',
);
