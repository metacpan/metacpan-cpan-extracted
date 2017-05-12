#!/usr/bin/perl -T
use strict;
use Test::More;
BEGIN { plan tests => 33 }
use Net::P0f;

my $p0f;

# create an object
$p0f = new Net::P0f;

# accessors
is( $p0f->chroot_as, undef,                 "chroot_as() default value: undef" );
is( $p0f->chroot_as('nobody'), undef,       " -> setting to 'nobody'" );
is( $p0f->chroot_as, 'nobody',              " -> checking" );

is( $p0f->fingerprints_file, undef,             "fingerprints_file() default value: undef" );
is( $p0f->fingerprints_file('p0f.fp'), undef,   " -> setting to 'p0f.fp''" );
is( $p0f->fingerprints_file, 'p0f.fp',          " -> checking" );

is( $p0f->interface, undef,                 "interface() default value: undef" );
is( $p0f->interface('eth0'), undef,         " -> setting to 'eth0'" );
is( $p0f->interface, 'eth0',                " -> checking" );

is( $p0f->dump_file, undef,                 "dump_file() default value: undef" );
is( $p0f->dump_file('network.dump'), undef, " -> setting to 'network.dump'" );
is( $p0f->dump_file, 'network.dump',        " -> checking" );

is( $p0f->detection_mode, 0,                "detection_mode() default value: 0" );
is( $p0f->detection_mode(1), 0,             " -> setting to 1" );
is( $p0f->detection_mode, 1,                " -> checking" );

is( $p0f->fuzzy, 0,                         "fuzzy() default value: 0" );
is( $p0f->fuzzy(1), 0,                      " -> setting to 1" );
is( $p0f->fuzzy, 1,                         " -> checking" );

is( $p0f->promiscuous, 0,                   "promiscuous() default value: 0" );
is( $p0f->promiscuous(1), 0,                " -> setting to 1" );
is( $p0f->promiscuous, 1,                   " -> checking" );

is( $p0f->filter, undef,                    "filter() default value: undef" );
is( $p0f->filter('net 192.168.1'), undef,   " -> setting to 'net 192.168.1'" );
is( $p0f->filter, 'net 192.168.1',          " -> checking" );

is( $p0f->masquerade_detection, 0,          "masquerade_detection() default value: 0" );
is( $p0f->masquerade_detection(1), 0,       " -> setting to 1" );
is( $p0f->masquerade_detection, 1,          " -> checking" );

is( $p0f->masquerade_detection_threshold, undef,        "masquerade_detection_threshold() default value: undef" );
is( $p0f->masquerade_detection_threshold(100), undef,   " -> setting to 100" );
is( $p0f->masquerade_detection_threshold, 100,          " -> checking" );

is( $p0f->resolve_names, 0,                 "resolve_names() default value: 0" );
is( $p0f->resolve_names(1), 0,              " -> setting to" );
is( $p0f->resolve_names, 1,                 " -> checking" );
