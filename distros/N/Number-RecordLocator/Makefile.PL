use inc::Module::Install;

name ('Number-RecordLocator');
author ('Jesse Vincent <jesse@bestpractical.com>');
version_from ('lib/Number/RecordLocator.pm');
abstract_from('lib/Number/RecordLocator.pm');
license('perl');
build_requires('Test::More');

&WriteAll;
