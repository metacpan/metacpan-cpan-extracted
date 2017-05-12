use strict;
use warnings;

use Authen::Bitcard;
use Data::Dumper;
use Plack::Request;
use Plack::Builder;
use XT::Util;

my $app = sub {
	my $env = shift;
	[ 200, [ Content_Type => "text/plain" ], [Dumper($env)] ];
};

# __CONFIG__ hashref comes from basic.psgi.config.
# See XT::Util for more info.
my $bc = "Authen::Bitcard"->new;
$bc->token( __CONFIG__->{token} );
$bc->api_secret( __CONFIG__->{secret} );

builder {
	enable "Auth::Bitcard", bitcard => $bc;
	$app;
};
