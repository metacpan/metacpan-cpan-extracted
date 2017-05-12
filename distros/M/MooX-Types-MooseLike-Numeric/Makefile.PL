use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %RUN_DEPS = (
  'MooX::Types::MooseLike' => 0.23,
);
my %BUILD_DEPS = (
  'Test::More'  => 0.96,
  'Test::Fatal' => 0.003,
  'Moo'         => 1.004002,
);

WriteMakefile(
  NAME => 'MooX::Types::MooseLike::Numeric',
  VERSION_FROM => 'lib/MooX/Types/MooseLike/Numeric.pm',
  PREREQ_PM => {
    %RUN_DEPS,
  },
  BUILD_REQUIRES => {
    %BUILD_DEPS,
  },
  META_ADD => {
    resources => {
      repository  => 'git://github.com/mateu/MooX-Types-MooseLike-Numeric.git',
      bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Types-MooseLike-Numeric',
      IRC         => 'irc://irc.perl.org/#web-simple',
    },
  },
  LICENSE => 'perl',
);
