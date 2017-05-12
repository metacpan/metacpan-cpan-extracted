use strict;
use warnings;
use Test::More tests => 2;

$ENV{MODULE_PORTABLEPATH_CONF} = 'eg/perlconfig.ini';
use_ok('Module::PortablePath');

is($Module::PortablePath::CONFIGS->{default}, $ENV{MODULE_PORTABLEPATH_CONF}, 'environment config passed ok');
