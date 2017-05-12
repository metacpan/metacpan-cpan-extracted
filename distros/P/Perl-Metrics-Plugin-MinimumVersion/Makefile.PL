use inc::Module::Install 0.75;

all_from      'lib/Perl/Metrics/Plugin/MinimumVersion.pm';
requires      'version'              => '0.74';
requires      'Perl::Metrics'        => '0.03';
requires      'Perl::MinimumVersion' => '0.15';
test_requires 'Test::More'           => '0.47';

WriteAll;
