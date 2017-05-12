use inc::Module::Install;
all_from 'lib/Parse/ACNS.pm';
readme_from 'lib/Parse/ACNS.pm';

repository 'https://github.com/bestpractical/parse-acns';

install_share;

requires 'XML::Compile::Schema';

requires 'Carp';
requires 'File::Spec';
requires 'Scalar::Util';
requires 'File::ShareDir';
requires 'File::Spec';

test_requires 'YAML::Any';
test_requires 'Test::More';
test_requires 'File::Spec';

sign;
WriteAll;
