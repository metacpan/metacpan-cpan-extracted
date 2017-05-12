use inc::Module::Install '0.68';

name 'Net-Akamai';
all_from 'lib/Net/Akamai.pm';

requires 'Moose' => '2.1202';
requires 'SOAP::Lite' => '0.710.05';
requires 'Crypt::SSLeay' => '0.57'; # needed for SOAP::Lite https
requires 'MooseX::AttributeHelpers' => '0.09';

# We need done_testing() and subtest() from more recent Test::More.
test_requires 'Test::More' => '0.94';

# generate README file
if ($Module::Install::AUTHOR) {
  system('pod2text lib/Net/Akamai.pm > README');
}

tests_recursive();
auto_install;
WriteAll;

