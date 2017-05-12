use strict;
use warnings;

use Test::More;

use Net::FreeIPA;

my $f = Net::FreeIPA->new(undef, debugapi => 1);

diag "Net::FreeIPA instance ", explain $f;

foreach my $mod ('', qw(Base API RPC Common)) {
    my $module = "Net::FreeIPA";
    $module .= "::$mod" if $mod;
    isa_ok($f, "$module", "instance is a $module instance");
}

isa_ok($f->{log}, 'Net::FreeIPA::DummyLogger',
       "Log atribute is initialized with a DummyLogger");

ok($f->{debugapi}, "debugapi attribute is set");

done_testing();
