use inc::Module::Install;

name         'Monitoring-Availability';
all_from     'lib/Monitoring/Availability.pm';
perl_version '5.008';
license      'perl';

requires 'Test::More'        => '0.87';

#test_requires 'Test::Pod' => 1.14;
#test_requires 'Test::Perl::Critic';
#test_requires 'Test::Pod::Coverage';
#test_requires 'Perl::Critic::Policy::Dynamic::NoIndirect';
#test_requires 'Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs';
#test_requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData';

auto_install;
WriteAll;
