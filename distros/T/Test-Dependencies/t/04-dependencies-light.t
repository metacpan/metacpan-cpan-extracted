#!perl

use Test::Needs qw( CPAN::Meta File::Find::Rule::Perl );

# yay bootstrap!
use Test::Dependencies exclude => [
    qw/Test::Dependencies
    CPAN::Meta CPAN::Meta::Requirements
   ExtUtils::MakeMaker
   File::Find::Rule::Perl
   Module::Metadata/],
    style => 'light';


ok_dependencies();
