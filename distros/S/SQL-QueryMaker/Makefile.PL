use inc::Module::Install;

all_from 'lib/SQL/QueryMaker.pm';
readme_from 'lib/SQL/QueryMaker.pm';

requires 'Scalar::Util';
test_requires 'Test::More' => 0.98;
test_requires 'Test::Requires';
test_requires 'DateTime';
test_requires 'Tie::IxHash';

WriteAll;
