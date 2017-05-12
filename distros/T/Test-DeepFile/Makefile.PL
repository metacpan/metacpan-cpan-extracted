use inc::Module::Install;

#install_as_vendor;

author_tests('xt');

# Define metadata
name 'Test-DeepFile';
all_from 'lib/Test/DeepFile.pm';

requires 'YAML' => 0.066;
requires 'Test::More' => 0.008;
requires 'Test::Deep' => 0.103;
test_requires 'Test::Exception' => 0.027;

WriteAll(sign => $ENV{SIGN});
