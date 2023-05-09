#!perl

use Test::Needs qw( CPAN::Meta File::Find::Rule::Perl );

# yay bootstrap!
# Ignore dependencies not USEd directly (CPAN::Meta & F::F::R::Perl)
use Test::Dependencies exclude => [
    qw/Test::Dependencies
    CPAN::Meta CPAN::Meta::Requirements
   ExtUtils::MakeMaker
   File::Find::Rule::Perl
   Module::Metadata/];

ok_dependencies();
