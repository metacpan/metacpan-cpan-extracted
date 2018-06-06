#!/usr/bin/perl -w

#
# I've been told at times that this or that sort function is
# faster for sorting IP addresses.  I've decied that I won't
# accept undocumented claims anymore.
#
# This file provides a way to test out sort functions.  If you
# think you've got a faster one, please try re-defining &mysortfunc.
# If it's faster, let me know.  If it's not, don't.
#

sub mysortfunc {
    return ( sort @_ );
}

BEGIN {
    unless ( -t STDOUT ) {    ## no critic: (InputOutput::ProhibitInteractiveTest)
        print "1..0 # Skipped: this is for people looking for faster sorts\n";
        exit(0);
    }
}

use Net::Netmask;
use Net::Netmask qw(int2quad quad2int imask);
use Carp;
use Carp qw(verbose);
use Benchmark qw(cmpthese);

sub generate {
    my ($count) = @_;

    my @list;
    while ( $count-- > 0 ) {
        my ( $o1, $o2, $o3, $o4 );
        my $class = int( rand(3) );
        if ( $class == 0 ) {
            ## class A ( 1.0.0.0 - 126.255.255.255 )
            $o1 = int( rand(126) ) + 1;
        } elsif ( $class == 1 ) {
            ## class B ( 128.0.0.0 - 191.255.255.255 )
            $o2 = int( rand(64) ) + 128;
        } else {
            ## class C ( 192.0.0.0 - 223.255.255.255 )
            $o3 = int( rand(32) ) + 192;
        }
        $o2   = int( rand(256) );
        $o3   = int( rand(256) );
        $o4   = int( rand(256) );
        $mask = int( sqrt( rand(1024) ) );
        my $i    = quad2int("$o1.$o2.$o3.$o4") & imask($mask);
        my $base = int2quad($i);
        push( @list, Net::Netmask->new("$base/$mask") );
    }

    return @list;
}

my (@iplist) = generate(5000);

cmpthese(
    -1,
    {
        candidate => sub {
            my (@x) = mysortfunc(@iplist);
        },
        distributed => sub {
            my (@x) = sort_network_blocks(@iplist);
        },
    }
);

