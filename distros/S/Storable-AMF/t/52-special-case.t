use ExtUtils::testlib;
# vim: ts=8 et sw=4 sts=4
use lib 't';
use strict;
use warnings;
use Storable::AMF0 qw(freeze thaw);
use Test::More tests=>4;
my @r = ();
my $x;


eval{
    $x = defined Storable::AMF0::thaw(undef);
};
ok(!$x && $@);
eval{
    $x = defined Storable::AMF3::thaw(undef);
};
ok(!$x && $@);
eval {
    my $s = chr(300);
    $x = defined Storable::AMF0::thaw(chr(300));
};
ok(!$x && $@);
eval {
    my $s = chr(300);
    $x = defined Storable::AMF0::thaw(chr(300));
};
ok(!$x && $@);
*{TODO} = *Test::More::TODO;
