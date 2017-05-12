use strict;
use warnings;
use inc::Module::Install;

name 'Monitoring-TT';
all_from 'lib/Monitoring/TT.pm';

license 'gpl3';
resources(
    'homepage',   => 'http://labs.consol.de',
    'bugtracker'  => 'https://github.com/sni/Monitoring-TT/issues',
    'repository', => 'https://github.com/sni/Monitoring-TT',
);

requires 'Pod::Usage' => 0;
requires 'Template'   => 0;

# requirements test requirements
feature     ('author_test',
  -default                                                                  => 0,
  'File::BOM'                                                               => 0,
  'Test::Cmd'                                                               => 0,
  'Test::Pod'                                                               => 1.40,
  'Test::Perl::Critic'                                                      => 0,
  'Test::Pod::Coverage'                                                     => 0,
  'Perl::Critic::Policy::Dynamic::NoIndirect'                               => 0,
  'Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs'          => 0,
  'Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData' => 0,
);

tests_recursive;
auto_install;
WriteAll;
