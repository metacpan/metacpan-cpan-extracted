#!perl
use warnings;
use strict;
use Test::More;
use Data::Dumper;

use lib qw(t/lib);
use Mock::LWP::UserAgent;
use Net::Topsy;

plan tests => 15;

{
    my $nt = Net::Topsy->new( key => 'foo' );
    isa_ok $nt, 'Net::Topsy';
    my $r = $nt->credit;
    isa_ok($r,'Net::Topsy::Result');
    my $ua = $nt->ua;
    isa_ok($ua, 'LWP::UserAgent');
}

{
    my @api_search_methods = qw/search searchcount profilesearch authorsearch/;
    my @api_url_methods = qw/trackbacks tags stats authorinfo urlinfo linkposts related trackbackcount/;

    for my $method (@api_search_methods) {
        my $nt     = Net::Topsy->new( key => 'foo' );
        my $result = $nt->$method( { q => 'lulz' } );
        isa_ok($result,'Net::Topsy::Result');
    }

    for my $method (@api_url_methods) {
        my $nt     = Net::Topsy->new( key => 'foo' );
        my $result = $nt->$method( { url => 'lolz' } );
        isa_ok($result,'Net::Topsy::Result');
    }
}

1;

