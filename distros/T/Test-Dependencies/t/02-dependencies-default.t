#!perl

# yay bootstrap!
use Test::Dependencies exclude => [qw/Test::Dependencies
   ExtUtils::MakeMaker  CPAN::Meta::Requirements Module::Metadata/];

ok_dependencies();
