use strict;
use inc::Module::Install;

name            ('Sim');
requires        (perl => '5.004001');
all_from        ('lib/Sim/Dispatcher.pm');

requires        ('Carp');
#requires        ('List::MoreUtils' => '0.21');

#tests('t/*.t t/*/*.t t/*/*/*t t/*/*/*/*.t');

no_index        (directory => 'sample');
auto_install;
WriteAll;

