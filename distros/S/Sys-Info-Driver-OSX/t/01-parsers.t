#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );

use Sys::Info::Driver::OSX;
use Sys::Info::Driver::OSX::OS;

SYSCTL_ROW: {
    my $p     = \&Sys::Info::Driver::OSX::_parse_sysctl_row;

    my $kb_10 = q~kern.boottime: { sec = 1305150689, usec = 0 } Thu May 12 00:51:29 2011~;
    my $kb_08 = q~kern.boottime = Thu Mar 31 17:43:09 2011~;

    my($name_10, $value_10) = $p->( $kb_10, 'kern.boottime', 10 );
    my($name_08, $value_08) = $p->( $kb_08, 'kern.boottime',  8 );

    ok( $name_10,  'Got a name for v10'  );
    ok( $value_10, 'Got a value for v10' );
    ok( $name_08,  'Got a name for v8'  );
    ok( $value_08, 'Got a value for v8' );

    is( $name_10, 'kern.boottime', 'Name for v10' );
    is( $value_10, '{ sec = 1305150689, usec = 0 } Thu May 12 00:51:29 2011',
        'Value for v10' );
    is( $name_08,  'kern.boottime',            'Name for v8'  );
    is( $value_08, 'Thu Mar 31 17:43:09 2011', 'Value for v8' );

}

UPTIME: {
    my $p     = \&Sys::Info::Driver::OSX::OS::_parse_uptime;

    my $stamp = q~Thu May 12 00:51:29 2011~;
    my $up_10 = $p->( q~{ sec = 1305161489, usec = 0 } Thu May 12 00:51:29 2011~,
                        'kern.boottime' );
    my $up_08 = $p->( $stamp , 'kern.boottime', 1 );

    ok( $up_10, 'Got uptime for v10' );
    ok( $up_08, 'Got uptime for v8'  );

    is( scalar gmtime $up_10, $stamp, 'Correct uptime for v10');
    is( scalar gmtime $up_08, $stamp, 'Correct uptime for v8' );
}
