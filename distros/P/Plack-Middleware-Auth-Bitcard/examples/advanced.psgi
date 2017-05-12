use strict;
use warnings;

use Authen::Bitcard;
use Data::Dumper;
use Plack::Request;
use Plack::Builder;
use XT::Util;

my $app = sub {
	my $env = shift;
	[
		200,
		[ Content_Type => "text/html" ],
		[
			"<title>".__FILE__."</title>\n",
			"<p>Authenticated as $env->{BITCARD}{username}</p>\n",
			"<p><a href='${\ $env->{BITCARD_URL}->(logout_url => $env) }'>Log out</a></p>\n",
			"<pre>".Dumper($env)."</pre>\n",
		]
	];
};

my $unauth_app = sub {
	my $env = shift;
	[
		200,
		[ Content_Type => "text/html" ],
		[
			"<title>".__FILE__."</title>\n",
			"<p>Not authenticated</p>\n",
			"<p><a href='${\ $env->{BITCARD_URL}->(login_url => $env) }'>Log in</a></p>\n",
			"<pre>".Dumper($env)."</pre>\n",
		]
	];
};


# __CONFIG__ hashref comes from advanced.psgi.config.
# See XT::Util for more info.
my $bc = "Authen::Bitcard"->new;
$bc->token( __CONFIG__->{token} );
$bc->api_secret( __CONFIG__->{secret} );

builder {
	enable "Auth::Bitcard",
		bitcard   => $bc,
		skip_if   => sub { my $req = "Plack::Request"->new(@_); $req->path =~ m{^/?public/} },
		on_unauth => $unauth_app;
	$app;
};
