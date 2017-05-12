use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;
 
WriteMakefile(
  NAME => 'Plack-Middleware-DiePretty',
  AUTHOR  => 'Justin Hunter <justin.d.hunter@gmail.com>',
  VERSION_FROM => 'lib/Plack/Middleware/DiePretty.pm',
  LICENSE => 'perl',
  ABSTRACT_FROM => 'lib/Plack/Middleware/DiePretty.pm',
  MIN_PERL_VERSION => '5.008001',
  PREREQ_PM => {
    'Plack::Middleware', => 0,
    'Try::Tiny' => 0,
    Template => 0,
    'Path::Class' => 0,
    FindBin => 0,
  },
  'BUILD_REQUIRES' => {
    'Test::More' => 0,
    'Plack::Test' => 0,
    'Plack::Builder' => 0,
    FindBin => 0,
  },
  META_MERGE      => {
    resources => {
      license     => 'http://dev.perl.org/licenses/',
      bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-DiePretty',
      repository  => 'https://github.com/arcanez/Plack-Middleware-DiePretty',
    },
  },
);
