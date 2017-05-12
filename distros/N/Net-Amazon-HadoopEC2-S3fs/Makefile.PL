use inc::Module::Install;
name 'Net-Amazon-HadoopEC2-S3fs';
all_from 'lib/Net/Amazon/HadoopEC2/S3fs.pm';

requires 'Moose';
requires 'Net::Amazon::S3';
requires 'Math::BigInt';
requires 'File::Basename';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'File::Temp';
build_requires 'File::Spec';

WriteAll;
