#!perl
use warnings;
use strict;
use Test::Exception;
use lib qw(t/lib);
use Mock::LWP::UserAgent;
use Net::Topsy;
use Test::More tests => 13;

my @api_search_methods = qw/search searchcount profilesearch authorsearch/;
my @api_url_methods = qw/trackbacks tags stats authorinfo urlinfo linkposts related trackbackcount/;

my $nt = Net::Topsy->new( key => 'foo' );

throws_ok( sub { my $nt = Net::Topsy->new( key => undef ) },
           qr/Attribute \(key\) does not pass the type constraint/,
);

for my $method (@api_search_methods) {
    throws_ok( sub {
            $nt->$method( { } );
        },
        qr/$method -> required params missing: q/,
    );
}

for my $method (@api_url_methods) {
    throws_ok( sub {
            $nt->$method( { } );
        },
        qr/$method -> required params missing: url/,
    );
}

