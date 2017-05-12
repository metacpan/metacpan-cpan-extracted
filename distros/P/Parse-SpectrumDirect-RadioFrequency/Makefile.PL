use inc::Module::Install;

name     'Parse-SpectrumDirect-RadioFrequency';
all_from 'lib/Parse/SpectrumDirect/RadioFrequency.pm';
author   q{Dave O'Neill <dmo@dmo.ca>};

build_requires 'Test::More';

WriteAll;
