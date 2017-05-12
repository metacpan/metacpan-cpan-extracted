#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# data for tests
my @domains = qw(     
    freshmeat.net
    freebsd.org
    reg.ru
    ns1.nameself.com.NS
    perl.com
);

my @domains_not_reg = qw(
    thereisnosuchdomain123.com
    thereisnosuchdomain453.ru
);

my @ips = qw( 87.242.73.95 );

my @registrars = ('REGRU-REG-RIPN');
my $server  = 'whois.ripn.net',

# start test
my $tests_qty = 2 + @domains + @domains_not_reg + @ips + @registrars;
plan tests    => 1 + $tests_qty;

use_ok('Net::Whois::Gateway::Client');

SKIP: {
    print "The following tests requires whois-gateway-d runned...\n";
    my $daemon_runned;
    eval {
        $daemon_runned = `ps e --cols=1000 | grep "whois-gateway-d"` ||
            $ENV{gateway_host};
    };

    no warnings 'once';
    $Net::Whois::Gateway::Client::default_host =
        $ENV{gateway_host} || 'localhost';

    skip "No whois-gateway-d detected...", $tests_qty
        if $@ || !$daemon_runned;
    
    ok( Net::Whois::Gateway::Client::ping(), 'ping' );

    ### by nrg
#    my @full_result = Net::Whois::Gateway::Client::whois(
#        query => \@domains,
#        force_directi  => 'yes',
#    );
    ### nrgs code end    

    my @full_result = Net::Whois::Gateway::Client::whois(
        query => \@domains,
    );
    foreach my $result ( @full_result ) {
        my $query = $result->{query} if $result;
        $query =~ s/.NS$//i;
        ok( $result && !$result->{error} && $result->{whois} =~ /$query/i,
            "whois for domain ".$result->{query}." from ".$result->{server} );
    }
    
    
    @full_result = Net::Whois::Gateway::Client::whois(
        query => \@registrars,
        server => $server,
    );
    foreach my $result ( @full_result ) {
        my $query = $result->{query} if $result;
        ok( $result && !$result->{error} && $result->{whois} =~ /$query/i,
            "whois for registrar  ".$result->{query}." from ".$result->{server} );
    }

    @full_result = Net::Whois::Gateway::Client::whois(
        query => \@domains_not_reg,
    );
    foreach my $result ( @full_result ) {
        ok(
            $result && $result->{error},
            "whois for domain (not reged) $result->{query}, error: " . 
                ( $result->{error} || 'blank' )
        );
    }
    
    @full_result = Net::Whois::Gateway::Client::whois(    
        query  => \@ips,
    );
    foreach my $result ( @full_result ) {
        ok( $result && !$result->{error} && $result->{whois},
            "whois for IP ".$result->{query}." from ".$result->{server} );
    }    

    eval {
	@full_result = Net::Whois::Gateway::Client::whois(    
	    query  => [ 'pleasetesttimeoutonthisdomainrequest.com' ],
	    timeout => 2,
	);
    };

    ok( $@ && $@ =~ /timeout/, 'timeout requests ok' );
}


1;
