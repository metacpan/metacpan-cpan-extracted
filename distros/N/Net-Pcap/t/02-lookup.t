#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

plan tests => 45;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$net,$mask,$result,$err) = ('','','','','');
my @devs = ();
my %devs = ();
my %devinfo = ();
my $ip_regexp = '/^[12]?\d+\.[12]?\d+\.[12]?\d+\.[12]?\d+$/';


# Testing error messages
SKIP: {
    skip "Test::Exception not available", 17 unless $has_test_exception;

    # lookupdev() errors
    throws_ok(sub {
        Net::Pcap::lookupdev()
    }, '/^Usage: Net::Pcap::lookupdev\(err\)/', 
       "calling lookupdev() with no argument");

    throws_ok(sub {
        Net::Pcap::lookupdev(0)
    }, '/^arg1 not a hash ref/', 
       "calling lookupdev() with incorrect argument type");

    SKIP: {
        skip "pcap_findalldevs() is not available", 11 unless is_available('pcap_findalldevs');
        # findalldevs() errors
        throws_ok(sub {
            Net::Pcap::findalldevs()
        }, '/^Usage: pcap_findalldevs\(devinfo, err\)/', 
           "calling findalldevs() with no argument");

        throws_ok(sub {
            Net::Pcap::findalldevs(0, 0, 0)
        }, '/^Usage: pcap_findalldevs\(devinfo, err\)/', 
           "calling findalldevs() with too many arguments");

        throws_ok(sub {
            Net::Pcap::findalldevs(0)
        }, '/^Usage: pcap_findalldevs\(devinfo, err\)/', 
           "calling 1-arg findalldevs() with incorrect argument type");

        throws_ok(sub {
            Net::Pcap::findalldevs(\%devinfo)
        }, '/^arg1 not a scalar ref/', 
           "calling 1-arg findalldevs() with incorrect argument type");

        throws_ok(sub {
            Net::Pcap::findalldevs(0, 0)
        }, '/^Usage: pcap_findalldevs\(devinfo, err\)/', 
           "calling 2-args findalldevs() with incorrect argument type");

        throws_ok(sub {
            Net::Pcap::findalldevs(\@devs, 0)
        }, '/^arg1 not a hash ref/', 
           "calling 2-args findalldevs() with incorrect argument type for arg1");

        throws_ok(sub {
            Net::Pcap::findalldevs(\$err, 0)
        }, '/^arg2 not a hash ref/', 
           "calling 2-args findalldevs() with incorrect argument type for arg2");

        throws_ok(sub {
            Net::Pcap::findalldevs(\%devinfo, 0)
        }, '/^arg2 not a scalar ref/', 
           "calling 2-args findalldevs() with incorrect argument type for arg2");

        # findalldevs_xs() errors
        throws_ok(sub {
            Net::Pcap::findalldevs_xs()
        }, '/^Usage: Net::Pcap::findalldevs_xs\(devinfo, err\)/', 
           "calling findalldevs_xs() with no argument");

        throws_ok(sub {
            Net::Pcap::findalldevs_xs(0, 0)
        }, '/^arg1 not a hash ref/', 
           "calling findalldevs_xs() with incorrect argument type for arg1");

        throws_ok(sub {
            Net::Pcap::findalldevs_xs(\%devinfo, 0)
        }, '/^arg2 not a scalar ref/', 
           "calling findalldevs_xs() with incorrect argument type for arg2");
    }

    # lookupnet() errors
    throws_ok(sub {
        Net::Pcap::lookupnet()
    }, '/^Usage: Net::Pcap::lookupnet\(device, net, mask, err\)/', 
       "calling lookupnet() with no argument");

    throws_ok(sub {
        Net::Pcap::lookupnet('', 0, 0, 0)
    }, '/^arg2 not a reference/', 
       "calling lookupnet() with incorrect argument type for arg2");

    throws_ok(sub {
        Net::Pcap::lookupnet('', \$net, 0, 0)
    }, '/^arg3 not a reference/', 
       "calling lookupnet() with incorrect argument type for arg3");

    throws_ok(sub {
        Net::Pcap::lookupnet('', \$net, \$mask, 0)
    }, '/^arg4 not a reference/', 
       "calling lookupnet() with incorrect argument type for arg4");
}


SKIP: {
    # Testing lookupdev()
    eval { $dev = Net::Pcap::lookupdev(\$err) };
    is(   $@,   '', "lookupdev()" );

    skip "error: $err. Skipping the rest of the tests", 27 if $err eq 'no suitable device found';

    is(   $err, '', " - \$err must be null: $err" ); $err = '';
    isnt( $dev, '', " - \$dev isn't null: '$dev'" );


    # Testing findalldevs()
    # findalldevs(\$err), legacy from Marco Carnut 0.05
    eval { @devs = Net::Pcap::findalldevs(\$err) };
    is(   $@,   '', "findalldevs() - 1-arg form, legacy from Marco Carnut 0.05" );
    is(   $err, '', " - \$err must be null: $err" ); $err = '';
    ok( @devs >= 1, " - at least one device must be present in the list returned by findalldevs()" );
    %devs = map { $_ => 1 } @devs;
    is( $devs{$dev}, 1, " - '$dev' must be present in the list returned by findalldevs()" );

    # findalldevs(\$err, \%devinfo), legacy from Jean-Louis Morel 0.04.02
    eval { @devs = Net::Pcap::findalldevs(\$err, \%devinfo) };
    is(   $@,   '', "findalldevs() - 2-args form, legacy from Jean-Louis Morel 0.04.02" );
    is(   $err, '', " - \$err must be null: $err" ); $err = '';
    ok( @devs >= 1, " - at least one device must be present in the list returned by findalldevs()" );
    ok( keys %devinfo >= 1, " - at least one device must be present in the hash filled by findalldevs()" );
    %devs = map { $_ => 1 } @devs;
    is( $devs{$dev}, 1, " - '$dev' must be present in the list returned by findalldevs()" );
    SKIP: {
        is( $devinfo{'any'}, 'Pseudo-device that captures on all interfaces', 
            " - checking pseudo-device description" ) and last if exists $devinfo{'any'};
        skip "Pseudo-device not available", 1;
    }
    SKIP: {
        is( $devinfo{'lo' }, 'Loopback device', " - checking loopback device description" ) 
            and last if exists $devinfo{'lo'};
        is( $devinfo{'lo0'}, 'Loopback device', " - checking loopback device description" ) 
            and last if exists $devinfo{'lo0'};
        skip "Can't predict loopback device description", 1;
    }


    SKIP: {
        skip "pcap_findalldevs() is not available", 7 unless is_available('pcap_findalldevs');

        # findalldevs(\%devinfo, \$err), new, correct syntax, consistent with libpcap(3)
        eval { @devs = Net::Pcap::findalldevs(\%devinfo, \$err) };
        is(   $@,   '', "findalldevs() - 2-args form, new, correct syntax, consistent with libpcap(3)" );
        is(   $err, '', " - \$err must be null: $err" ); $err = '';
        ok( @devs >= 1, " - at least one device must be present in the list returned by findalldevs()" );
        ok( keys %devinfo >= 1, " - at least one device must be present in the hash filled by findalldevs()" );
        %devs = map { $_ => 1 } @devs;
        is( $devs{$dev}, 1, " - '$dev' must be present in the list returned by findalldevs()" );
        SKIP: {
            is( $devinfo{'any'}, 'Pseudo-device that captures on all interfaces', 
                " - checking pseudo-device description" ) and last if exists $devinfo{'any'};
            skip "Pseudo-device not available", 1;
        }
        SKIP: {
            is( $devinfo{'lo' }, 'Loopback device', " - checking loopback device description" ) 
                and last if exists $devinfo{'lo'};
            is( $devinfo{'lo0'}, 'Loopback device', " - checking loopback device description" ) 
                and last if exists $devinfo{'lo0'};
            skip "Can't predict loopback device description", 1;
        }
    }


    # Testing lookupnet()
    eval { $result = Net::Pcap::lookupnet($dev, \$net, \$mask, \$err) };
    is(   $@,    '', "lookupnet()" );

    SKIP: {
        skip "error: $err. Skipping lookupnet() tests", 6 if $result == -1;

        is(   $err,  '', " - \$err must be null: $err" ); $err = '';
        is(  $result, 0, " - \$result must be null: $result" );
        isnt( $net,  '', " - \$net isn't null: '$net' => ".dotquad($net) );
        isnt( $mask, '', " - \$mask isn't null: '$mask' => ".dotquad($mask) );
        like( dotquad($net),  $ip_regexp, " - does \$net look like an IP address?" );
        like( dotquad($mask), $ip_regexp, " - does \$mask look like an IP address?" );
    }
}


sub dotquad {
    my($na, $nb, $nc, $nd);
    my($net) = @_ ;
    $na = $net >> 24 & 255 ;
    $nb = $net >> 16 & 255 ;
    $nc = $net >>  8 & 255 ;
    $nd = $net & 255 ;
    return "$na.$nb.$nc.$nd"
}
