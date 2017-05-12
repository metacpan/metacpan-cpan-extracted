use strict;
use warnings;
use Test::More;
use Sys::HostIP;

plan tests => $^O =~ qr/(MSWin32|cygwin)/ ? 5 : 7;

{
    no warnings 'redefine';

    *Sys::HostIP::_get_ifconfig_binary = sub {
        my $object = shift;
        isa_ok( $object, 'Sys::HostIP' );
        cmp_ok( @_, '==', 0, 'Got no parameters' );
        return 'test';
    };

    *Sys::HostIP::_get_interface_info = sub {};
}

is( Sys::HostIP->ifconfig, 'test', 'ifconfig without object' );

my $object = Sys::HostIP->new;
is( $object->ifconfig('my_path'), 'my_path', 'ifconfig with object and param' );

$object->{'ifconfig'} = 'my_ifconfig';
is( $object->ifconfig, 'my_ifconfig', 'ifconfig without path');

