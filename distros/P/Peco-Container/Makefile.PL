use inc::Module::Install;

name('Peco-Container');
author('Richard Hundt <perl@kulabs.com>');
abstract('Light Inversion of Control container');
license('artistic');
version_from('lib/Peco/Container.pm');
build_requires('Test::More');

my @depends = qw/
    Carp
    Scalar::Util
/;

requires( map { $_ => undef } @depends );

check_nmake();
&WriteAll();
