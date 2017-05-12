#!perl -T
use strict;
use warnings;
use Test::More;


# public API
my $module = "Net::RawIP";

my @exported_functions = qw(
    dispatch
    dump
    dump_open
    loop
    linkoffset
    ifaddrlist
    open_live
    rdev
    timem
);

my @class_methods = qw(
    new
    optget
    optset
    optunset
);

my @object_methods = qw(
    
);


# tests plan
plan tests => 1 + 2 * @exported_functions + 1 * @class_methods + 2 + 2 * @object_methods;

# load the module
use_ok( $module );

# check functions
for my $function (@exported_functions) {
    can_ok($module, $function);
    can_ok(__PACKAGE__, $function);
}

# check class methods
for my $methods (@class_methods) {
    can_ok($module, $methods);
}

# check object methods
my $object = eval { $module->new };
is( $@, "", "creating a $module object" );
isa_ok( $object, $module, "check that the object" );

for my $method (@object_methods) {
    can_ok($module, $method);
    can_ok($object, $method);
}

__END__

# subs defined in lib/New/RawIP.pm
qw<
    N2L
    _pack
    _unpack
    bset
    ethnew
    ethsend
    ethset
    generic_default
    get
    icmp_default
    mac
    n2L
    packet
    pcapinit
    pcapinit_offline
    proto
    s2i
    send
    send_eth_frame
    set
    tcp_default
    udp_default
>;
