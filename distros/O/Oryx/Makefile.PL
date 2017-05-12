use inc::Module::Install;

name('Oryx');
author('Richard Hundt <richard NO SPAM AT protea-systems.com>');
abstract('Object Persistence with Multiple Inheritance');
license('artistic');
version_from('lib/Oryx.pm');
build_requires($_) for (qw[
    DBI
    YAML
    Class::Observable
    Class::Data::Inheritable
    Class::Date
    DBD::SQLite
    DBM::Deep
    Test::More
    Data::Types
    File::Spec
    Module::Pluggable
]);

requires($_) for (qw[
    DBI
    YAML
    Class::Observable
    Class::Data::Inheritable
    Class::Date
    SQL::Abstract
    Ima::DBI
    DBD::SQLite
    DBM::Deep
    Data::Types
    File::Spec
    Module::Pluggable
]);

check_nmake();
&WriteAll();
