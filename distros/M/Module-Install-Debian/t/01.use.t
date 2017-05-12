use strict;
use warnings;
use Test::More tests => 1;
use Module::Install::Debian;

my $d = Module::Install::Debian->new();
isa_ok( $d, "Module::Install::Debian", "right class" );

