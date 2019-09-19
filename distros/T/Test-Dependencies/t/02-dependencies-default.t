#!perl

use Test::Needs qw( CPAN::Meta File::Find::Rule::Perl );

# yay bootstrap!
use Test::Dependencies exclude => [qw/Test::Dependencies
   ExtUtils::MakeMaker  CPAN::Meta::Requirements Module::Metadata/];

ok_dependencies();
