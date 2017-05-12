use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  NAME => 'Foo::Bar',
  DISTNAME => 'Foo-Bar',
  ABSTRACT => "Best Foo module ever",
  VERSION => '0.10',
  AUTHOR => 'Ingy döt Net <ingy@cpan.org>',
  LICENSE => 'perl',
);

WriteMakefile(%WriteMakefileArgs);
