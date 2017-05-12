use inc::Module::Install;

name     'Sendmail-Queue';
all_from 'lib/Sendmail/Queue.pm';

requires 'File::Spec';
requires 'IO::File';
requires 'Scalar::Util';
requires 'Time::Local';
requires 'Mail::Header::Generator';
requires 'Storable';

build_requires 'Test::Most';
build_requires 'Test::Class';

WriteAll;
