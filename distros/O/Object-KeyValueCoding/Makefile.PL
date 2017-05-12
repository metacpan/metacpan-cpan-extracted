use inc::Module::Install;

name           'Object-KeyValueCoding';
all_from       'lib/Object/KeyValueCoding.pm';

# Specific dependencies
requires       'Scalar::Util';
requires       'List::MoreUtils';
test_requires  'Test::More'  => '0.42';

WriteAll;