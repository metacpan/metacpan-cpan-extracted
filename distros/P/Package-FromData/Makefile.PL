use inc::Module::Install;

use 5.010; # 5.10 required

name 'Package-FromData';
all_from 'lib/Package/FromData.pm';

requires 'Exporter';
requires 'Readonly';
requires 'Test::Deep::NoTest';
requires 'Scalar::Util';
build_requires 'Test::Exception';
build_requires 'Test::More';
build_requires 'ok';


WriteAll();
