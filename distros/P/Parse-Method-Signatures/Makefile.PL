use lib 'inc';
use Module::Install 0.91 ();
BEGIN {
  $INC{'inc/Module/Install.pm'} = $INC{'Module/Install.pm'};
  inc::Module::Install->import
}

use strict;
use warnings;

name 'Parse-Method-Signatures';
all_from 'lib/Parse/Method/Signatures.pm';

requires 'Class::Load' => '0.19';
requires 'List::MoreUtils' => '0.20';
requires 'Moose';
requires 'MooseX::Traits' => '0.06';
requires 'MooseX::Types' => '0.17';
requires 'MooseX::Types::Moose';
requires 'MooseX::Types::Structured';
requires 'namespace::clean' => '0.10';
requires 'PPI' => '1.203';

test_requires 'aliased';
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::Differences';
test_requires 'MooseX::Types::Structured';

postamble(<<"EOM");
testcover: pm_to_blib
\tcover -delete
\tHARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test
\tcover
EOM

resources(
    'repository' => 'git://github.com/ashb/Parse-Method-Signatures.git',
    'homepage'   => 'http://github.com/ashb/Parse-Method-Signatures/tree/master',
);

auto_provides;
auto_install();
WriteAll;
