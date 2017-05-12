#!/usr/bin/perl -w

use strict;
use LWP::UserAgent;
use Test::More;
use Net::Whois::Raw;
use Test::RequiresInternet;

no warnings;
$Net::Whois::Raw::CHECK_FAIL   = 2;
$Net::Whois::Raw::OMIT_MSG     = 2;
$Net::Whois::Raw::CHECK_EXCEED = 2;
$Net::Whois::Raw::TIMEOUT      = 10;

my $DEBUG = 0;
my $fake_domain = 'fake123domain';
my %pseudo_tlds = map {$_ => 1} qw/ARPA NS RIPE IP/;
my $tests_number = keys( %Net::Whois::Raw::Data::servers ) * 2;

for my $tld ( sort keys %Net::Whois::Raw::Data::servers ) {
    SKIP: {    
        skip( "Pseudo tld $tld", 2 )  if $pseudo_tlds{ $tld };

        my $server = $Net::Whois::Raw::Data::servers{ $tld };
        my $domain = get_domain( $tld );        
        skip( "Cant find domain in .$tld", 2 )  unless $domain;
        
        my $whois = eval { whois( $domain ) };
        print "---------------\n$whois\n-------------\n" if $DEBUG;
        
        if ( $@ ) {
            ok 0, "TLD: $tld,\tdomain: $domain,\tserver: $server\t - timeout";
        } else {
            ok $whois, "TLD: $tld,\tdomain: $domain,\tserver: $server";
        }
        
        $domain = "$fake_domain.$tld";
        $whois = eval { whois( $domain ) };
        
        if ( $@ ) {
            ok 0, "TLD: $tld,\tdomain: $domain,\tserver: $server\t - timeout";
        } else {
            ok !$whois, "TLD: $tld,\tdomain: $domain,\tserver: $server";
        }
        print "\n";
    }
 
};

sub get_domain {
    my $tld = shift;
    
    my $content = get_google( $tld );
    my ( $domain ) = $content =~ /<a href=".+?:\/\/.*?(\w+\.$tld)\//i;
    
    return $domain;
}

sub get_google {
    my $tld = shift;
  
    my $ua = LWP::UserAgent->new( parse_head => 0 );
    $ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.10) Gecko/20071128 Fedora/2.0.0.10-2.fc7 Firefox/2.0.0.10");    
    my $req = HTTP::Request->new(
        GET => 'http://www.google.com.ua/search?q=site:' . $tld
    );
    my $res = $ua->request( $req );
    
    return $res->content;
}
