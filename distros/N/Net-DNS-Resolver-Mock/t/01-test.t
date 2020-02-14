#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

use Net::DNS::Resolver::Mock;

plan tests => 20;

{
    my $Resolver = Net::DNS::Resolver::Mock->new();
    my $Reply = $Resolver->query( 'google.com', 'A' );
    is( defined( $Reply ), '', 'Bare resolver returns nothing' );
}

{
    my $ZoneData = join( "\n",
        'example.com 3600 A 1.2.3.4',
    );

    my $Resolver = Net::DNS::Resolver::Mock->new();
    $Resolver->zonefile_parse( $ZoneData );

    my $Reply;

    $Reply = $Resolver->query( 'google.com', 'A' );
    is( defined( $Reply ), '', 'Missing entry returns nothing' );

    $Reply = $Resolver->query( 'example.com', 'A' );
    is( defined( $Reply ), 1, 'Valid entry returns set' );
    is( ref $Reply, 'Net::DNS::Packet', 'Net::DNS::Packet object returned' );
    is( ref $Reply->{ 'answer' }->[0], 'Net::DNS::RR::A', 'New::DNS::RR::A object returned' );
    is( $Reply->{ 'answer' }->[0]->rdatastr(), '1.2.3.4', 'Correct IP Address returned' );;
}

{
    my $Resolver = Net::DNS::Resolver::Mock->new();
    $Resolver->zonefile_read( 't/zonefile' );

    my $Reply;

    $Reply = $Resolver->query( 'google.com', 'A' );
    is( defined( $Reply ), '', 'Missing entry returns nothing' );

    $Reply = $Resolver->query( 'example.net', 'A' );
    is( defined( $Reply ), 1, 'Valid entry returns set' );
    is( ref $Reply, 'Net::DNS::Packet', 'Net::DNS::Packet object returned' );
    is( ref $Reply->{ 'answer' }->[0], 'Net::DNS::RR::A', 'New::DNS::RR::A object returned' );
    is( $Reply->{ 'answer' }->[0]->rdatastr(), '5.6.7.8', 'Correct IP Address returned' );;

    $Reply = $Resolver->query( '8.6.4.2', 'PTR' );
    is( ref $Reply->{ 'answer' }->[0], 'Net::DNS::RR::PTR', 'New::DNS::RR::PTR object returned' );
    is( $Reply->{ 'answer' }->[0]->rdatastr(), 'reverse.example.com.', 'Correct Address returned' );;

    $Reply = $Resolver->query( '9.7.5.3', 'PTR' );
    is( ref $Reply->{ 'answer' }->[0], 'Net::DNS::RR::CNAME', 'New::DNS::RR::CNAME object returned' );
    is( $Reply->{ 'answer' }->[0]->rdatastr(), '2.4.6.8.in-addr.arpa.', 'Correct CNAME returned' );;

    $Reply = $Resolver->query( '2.4.6.8.in-addr.arpa.', 'PTR' );
    is( ref $Reply->{ 'answer' }->[0], 'Net::DNS::RR::PTR', 'New::DNS::RR::PTR object returned' );
    is( $Reply->{ 'answer' }->[0]->rdatastr(), 'reverse.example.com.', 'Correct Address returned' );;

    $Reply = $Resolver->query( 'cnameptr.example.com.', 'PTR' );
    is( ref $Reply->{ 'answer' }->[0], 'Net::DNS::RR::PTR', 'New::DNS::RR::PTR object returned' );
    is( $Reply->{ 'answer' }->[0]->rdatastr(), 'reverse.example.com.', 'Correct Address returned' );;

    $Resolver->die_on( 'cnameptr.example.com.', 'PTR', 'Die Test' );;
    dies_ok( sub{ $Resolver->query( 'cnameptr.example.com.', 'PTR' ) }, 'Dies ok' );
}

