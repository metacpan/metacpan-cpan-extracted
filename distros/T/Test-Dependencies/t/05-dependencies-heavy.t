#!perl

use Test::Needs 'B::PerlReq', 'PerlReq::Utils';

# yay bootstrap!
use Test::Dependencies exclude => [
    qw/Test::Dependencies
      ExtUtils::MakeMaker  CPAN::Meta::Requirements Module::Metadata /
  ],
  style => 'heavy';

ok_dependencies();
