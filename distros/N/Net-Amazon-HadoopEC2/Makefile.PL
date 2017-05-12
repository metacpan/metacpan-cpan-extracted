use inc::Module::Install;

name 'Net-Amazon-HadoopEC2';
all_from 'lib/Net/Amazon/HadoopEC2.pm';

requires 'Moose';
requires 'Moose::Util::TypeConstraints';
requires 'Carp';
requires 'Net::Amazon::EC2';
requires 'Net::SSH::Perl';
requires 'File::Spec';
requires 'Path::Class::File';
requires 'File::Basename';
requires 'MIME::Base64';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'File::Temp';
test_requires 'Digest::MD5';

WriteAll;
