#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

use Net::DNS::Resolver::Mock;

plan tests => 10;

{
    my $ZoneData = join( "\n",
        'example.com 3600 A 1.2.3.4',
    );

    my $Resolver = Net::DNS::Resolver::Mock->new();
    $Resolver->zonefile_parse( $ZoneData );

    my $Reply;

    $Reply = $Resolver->query( 'google.com', 'A' );
    is( defined( $Reply ), '', 'Missing entry returns nothing' );

    my @Debug = $Resolver->get_debug;
    is_deeply ( \@Debug, [], 'Disabled debugging does not log' );

    $Resolver->enable_debug;

    $Reply = $Resolver->query( 'google.com', 'A' );
    is( defined( $Reply ), '', 'Missing entry returns nothing' );

    @Debug = $Resolver->get_debug;
    is_deeply ( \@Debug, [ "Net::DNS::Resolver::Mock Debugging enabled", "DNS Lookup 'google.com' 'A'" ], 'Enabled debugging logs' );

    $Reply = $Resolver->query( 'google.com.au', 'TXT' );
    is( defined( $Reply ), '', 'Missing entry returns nothing' );

    @Debug = $Resolver->get_debug;
    is_deeply ( \@Debug, [ "Net::DNS::Resolver::Mock Debugging enabled", "DNS Lookup 'google.com' 'A'", "DNS Lookup 'google.com.au' 'TXT'" ], 'Enabled debugging logs' );

    $Reply = $Resolver->query( 'google.com.au', 'TXT' );
    is( defined( $Reply ), '', 'Missing entry returns nothing' );

    @Debug = $Resolver->get_debug;
    is_deeply ( \@Debug, [ "Net::DNS::Resolver::Mock Debugging enabled", "DNS Lookup 'google.com' 'A'", "DNS Lookup 'google.com.au' 'TXT'", "DNS Lookup 'google.com.au' 'TXT'" ], 'Enabled debugging logs' );

    $Resolver->disable_debug;

    $Reply = $Resolver->query( 'google.com', 'A' );
    is( defined( $Reply ), '', 'Missing entry returns nothing' );

    @Debug = $Resolver->get_debug;
    is_deeply ( \@Debug, [], 'Disabled debugging does not log' );

}

