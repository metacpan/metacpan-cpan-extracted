
use warnings;
$^W = 1;
use strict;

use Apache::Test ':withtestmore';
use Test::More;

use Apache::TestConfig;
use Apache::TestRequest qw(GET POST);

if ($main::location =~ /mod_perl/) {
	eval 'use Apache2::Request;';
	if ($@) {
		plan skip_all => 'No Apache2::Request, skipping';
		exit;
	}
}

if ($main::location =~ /storable/) {
	eval 'use Apache2::SubProcess;';
	if ($@) {
		plan skip_all => 'No Apache2::SubProcess, skipping';
		exit;
	}
}

plan tests => 123;

my $VERSION = '2.004';

my $hostport = Apache::TestRequest::hostport;

my ($uri, $res, $body);

ok(1, $uri = "/$main::location/app1.xml");
ok($res = GET($uri), 'Did we GET some response?');
is($res->code, 200, 'Success response code?');
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');
$body = $res->content;
is($body, <<EOF, "It should have returned 13 and $main::rayapp_env_data");
<?xml version="1.0"?>
<?xml-stylesheet href="appx.html.xsl"?>
<root>
	<id>13</id>
	<data>$main::rayapp_env_data</data>
	<version>$VERSION</version>
</root>
EOF

ok(1, $uri = "/$main::location/app1.html");
ok($res = GET($uri), 'GOT some response?');
is($res->code, 200, "Test the response code");
$body = $res->content;
if ($main::location eq 'mod_perl_proxy1'
	or $main::location eq 'mod_perl_proxy3_cgi') {	# these have pdir
	is($res->header('Content-Type'), 'text/plain; charset=UTF-8', 'The data should be text/plain; charset=UTF-8');
	is($body, <<EOF, "It should have used the local stylesheet according to PI (app1.html.xsl)");
The id is 13,
the data is $main::rayapp_env_data.
EOF
} else {
	is($res->header('Content-Type'), 'text/html; charset=UTF-8', 'The data should be text/html; charset=UTF-8');
	is($body, <<EOF, "It should have used the stylesheet according to PI (app1.html.xsl)");
<html><body><p>The id is <span id="id">13</span>,
	the data is <span id="data">$main::rayapp_env_data</span>.
</p></body></html>
EOF
}


ok(1, $uri = "/$main::location/app3.html");
ok($res = GET($uri), 'GOT some response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/html; charset=UTF-8', 'The data should be text/html; charset=UTF-8');
$body = $res->content;
is($body, <<EOF, "It should have used the stylesheet app3.xsl");
<html><body>
<p>The id is <span id="id">13</span>,
	the data is <span id="data">$main::rayapp_env_data</span>.
</p>
<p><a href="app3.html">Style data is Káťa
	and style env data is $main::rayapp_env_style_data</a></p>
<ul>
<li><a href="http://$hostport">base url</a></li>
<li>
<a href="/$main::location/app3.html">url</a> is the same as <a href="/$main::location/app3.html">absolute url</a>
</li>
<li><a href="app3.html">relative url</a></li>
<li><a href="app3.html">relative url with query</a></li>
</ul>
</body></html>
EOF



ok(1, $uri = "/$main::location/app3.html?m=35;n=auto&id=17");
ok($res = GET($uri), 'GOT some response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/html; charset=UTF-8', 'The data should be text/html; charset=UTF-8');
$body = $res->content;
is($body, <<EOF, "It should have used the stylesheet app3.xsl");
<html><body>
<p>The id is <span id="id">13</span>,
	the data is <span id="data">$main::rayapp_env_data</span>.
</p>
<p><a href="app3.html">Style data is Káťa
	and style env data is $main::rayapp_env_style_data</a></p>
<ul>
<li><a href="http://localhost.localdomain:8529">base url</a></li>
<li>
<a href="/$main::location/app3.html">url</a> is the same as <a href="/$main::location/app3.html">absolute url</a>
</li>
<li><a href="app3.html">relative url</a></li>
<li><a href="app3.html?m=35;n=auto&amp;id=17">relative url with query</a></li>
</ul>
</body></html>
EOF





ok(1, $uri = "/$main::location/");
ok($res = GET($uri), 'Did we GET HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/html; charset=UTF-8', 'The data should be text/html; charset=UTF-8');
$body = $res->content;
is($body, <<EOF, "Request for directory should give app3.html");
<html><body>
<p>The id is <span id="id">13</span>,
	the data is <span id="data">$main::rayapp_env_data</span>.
</p>
<p><a href="./">Style data is Káťa
	and style env data is $main::rayapp_env_style_data</a></p>
<ul>
<li><a href="http://$hostport">base url</a></li>
<li>
<a href="/$main::location/">url</a> is the same as <a href="/$main::location/">absolute url</a>
</li>
<li><a href="./">relative url</a></li>
<li><a href="./">relative url with query</a></li>
</ul>
</body></html>
EOF

ok(1, $uri = "/$main::location");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/html; charset=UTF-8', 'The data should be text/html; charset=UTF-8');
$body = $res->content;
is($body, <<EOF, "And so should uri without the trailing slash");
<html><body>
<p>The id is <span id="id">13</span>,
	the data is <span id="data">$main::rayapp_env_data</span>.
</p>
<p><a href="./">Style data is Káťa
	and style env data is $main::rayapp_env_style_data</a></p>
<ul>
<li><a href="http://$hostport">base url</a></li>
<li>
<a href="/$main::location/">url</a> is the same as <a href="/$main::location/">absolute url</a>
</li>
<li><a href="./">relative url</a></li>
<li><a href="./">relative url with query</a></li>
</ul>
</body></html>
EOF

ok(1, $uri = "/$main::location/app2.html");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/html; charset=UTF-8', 'The data should be text/html; charset=UTF-8');
$body = $res->content;
is($body, <<EOF, "Should use the stylesheet app2.xsl");
<html><body><p>The id is <span id="id">13</span>,
	the data is <span id="data">$main::rayapp_env_data</span>.
</p></body></html>
EOF

ok(1, $uri = "/$main::location/text.xml");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/plain', 'The data should be text/plain');
$body = $res->content;
is($body, <<EOF, "We should have got the output via print");
Output.
EOF

ok(1, $uri = "/$main::location/302.xml");
ok($res = GET($uri, redirect_ok => 0),
	'Did we get HTTP::Response?');
is($res->code, 302, "Test the response code, redirect");
is($res->header('Content-Type'), 'text/plain', 'The data should be text/plain');
is($res->header('Location'), 'http://perl.apache.org/', 'The redirection target');
$body = $res->content;
is($body, <<EOF, "The 302 response can have text");
Check the mod_perl website, perl.apache.org.
EOF

ok(1, $uri = "/$main::location/xml.xml");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');
$body = $res->content;
is($body, <<EOF, "Request for xml.xml should skip the DSD and give us the XML");
<?xml version="1.0"?>
<data>
	Note, this is not DSD, it should be processed as is.
	<_param name="id"/>
	<id/>
</data>
EOF

ok(1, $uri = "/$main::location/xml.html");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/html; charset=UTF-8', 'The data should be text/html');
$body = $res->content;
is($body, <<EOF, "It should skip the DSD and give us the output of xml.xml -> xml.xsl");
<html><body>
<p>
We have _param element here.
</p>
<p>
We have the empty id element here.
</p>
</body></html>
EOF

ok(1, $uri = "/$main::location/xml.txt");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/plain; charset=UTF-8', 'The data should be text/plain');
$body = $res->content;
is($body, <<EOF, "GET /$main::location/xml.txt should skip the DSD and give us the plain text");


Output:


We have _param element here.

We have the empty id element here.
EOF

ok(1, $uri = "/$main::location/nonexistent.xml");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 404, "We expect 404 Not found code");
$body = $res->content;
if ($main::location =~ /^cgi[12]$/) {
	is($res->header('Content-Type'), 'text/plain', 'The plain message');
	is($body, <<EOF, "GET /$main::location/nonexistent.xml should return 404 message");
The requested URL was not found on this server.
EOF
} else {
	is($res->header('Content-Type'), 'text/html; charset=iso-8859-1', 'The HTML message');
	is($body, <<EOF, "GET /$main::location/nonexistent.xml should return 404 message");
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL /$main::location/nonexistent.xml was not found on this server.</p>
</body></html>
EOF
}

ok(1, $uri = "/$main::location/processq.xml");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');
$body = $res->content;
is($body, <<EOF, "GET /$main::location/processq.xml should return empty XML");
<?xml version="1.0"?>
<application>
</application>
EOF

ok(1, $uri = "/$main::location/processq.xml?id=123");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');
$body = $res->content;
is($body, <<EOF, "GET /$main::location/processq.xml should return id: 123");
<?xml version="1.0"?>
<application>
	<out_id>123</out_id>
</application>
EOF

ok(1, $uri = "/$main::location/processq.xml?value=123;id=jezek");
ok($res = GET($uri), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');
$body = $res->content;
is($body, <<EOF, "GET /$main::location/processq.xml should return id: jezek and value: 123");
<?xml version="1.0"?>
<application>
	<out_id>jezek</out_id>
	<out_value>123</out_value>
</application>
EOF

ok(1, $uri = "/$main::location/processq.xml?value=123;id=jezek");
ok($res = POST("/$main::location/processq.xml?value=123;id=jezek",
	[ id => 45, value => 'krtek' ]), 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');
$body = $res->content;
is($body, <<EOF, "POST /$main::location/processq.xml should return POSTed values");
<?xml version="1.0"?>
<application>
	<out_id>45</out_id>
	<out_value>krtek</out_value>
</application>
EOF

my ($request, $ua);

ok(1, $uri = "http://$hostport/$main::location/processq.xml?value=888");
$request = new HTTP::Request POST => $uri;
$request->content_type('application/x-www-form-urlencoded');
$request->content('id=32&value=jezek');
$ua = new LWP::UserAgent;
$res = $ua->request($request);
ok($res, 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');
$body = $res->content;
is($body, <<EOF, "POST /$main::location/processq.xml should return POSTed values");
<?xml version="1.0"?>
<application>
	<out_id>32</out_id>
	<out_value>jezek</out_value>
</application>
EOF


ok(1, $uri = "http://$hostport/$main::location/processq.xml?value=88");
$request = new HTTP::Request POST => $uri;
$request->content_type('text/plain');
$request->content('This is freeform content where a = 1');
$ua = new LWP::UserAgent;
$res = $ua->request($request);
ok($res, 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');
$body = $res->content;
is($body, <<EOF, "GET /$main::location/processq.xml should process the body of the request");
<?xml version="1.0"?>
<application>
	<out_value>This is freeform content where a = 1</out_value>
</application>
EOF


SKIP: {

skip "For CGI, we always fetch a new process.", 2 if $main::location =~ /cgi/;

my ($CHANGING, $changing_ok, %server_pids);

$CHANGING = 't/htdocs/ray/changing.mpl';
unlink $CHANGING;					# purge leftovers

$changing_ok = 'skip';
%server_pids = ();;
$uri = "/$main::location/changing.xml";
for my $i (1 .. 10) {
	my $script = <<"EOF";
use strict;
use warnings;
sub handler {
	return {
		pid => \$\$,
		multiplied_pid => \$\$ * $i,
	};
}
1;
EOF
	print "# Will try to GET $uri with multiplication $i\n";
	my $ret = eval {
		open OUT, "> $CHANGING" or die "Failed to open $CHANGING for writing: $!\n";
		print OUT $script or die "Failed to write $CHANGING: $!\n";
		close OUT or die "Failed to close $CHANGING: $!\n";

		$res = GET($uri) or die "Failed GET the [$uri]\n";
		$res->code eq 200 or die "The status is @{[ $res->code ]}, not good\n";
		$body = $res->content;
		my ($server_id, $multiply) = ($body =~ m!<pid>(\d+)</pid>.*<multiplied_pid>(\d+)</multiplied_pid>!s);
		$server_id or die "We did not get server pid\n";
		($multiply eq ($server_id * $i)) or die "Got output $multiply, expected @{[ $server_id * $i ]}\n";
		if (not exists $server_pids{$server_id}) {
			$server_pids{$server_id} = $multiply;
		} elsif ($server_pids{$server_id} eq $multiply) {
			die "Got the same multiply, so the same code was reused\n";
		} else {
			print "# Script changed ok\n";
			$changing_ok = 'yes';
			return 1;
		}
		return;
	};
	last if $ret;
	if ($@) {
		my $out = $@;
		$out =~ s/^/# /m;
		print $out;
		$changing_ok = 'no';
		last;
	}
	sleep 1;
}

if ($changing_ok eq 'skip') {
	SKIP: {
		skip "Tried multiple times but failed to hit the same
		server to check how it handles changes in script code.", 1;
	}
} elsif ($changing_ok eq 'no') {
	ok(0, "Will we notice when the application code changes?");
} elsif ($changing_ok eq 'yes') {
	ok(1, "We notice changes in application code ok.");
} else {
	ok(0, "Some strange problem with the test suite.");
}

$CHANGING = 't/htdocs/ray/changing.xsl';
unlink $CHANGING;					# purge leftovers

$changing_ok = 'skip';
%server_pids = ();
$uri = "/$main::location/changing.html";
for my $i (1 .. 10) {
	my $xsl = <<"EOF";
<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/out">pid [<xsl:value-of select="pid"/>] $i</xsl:template>
</xsl:stylesheet>
EOF
	print "# Will try to GET $uri with value $i\n";
	my $ret = eval {
		open OUT, "> $CHANGING" or die "Failed to open $CHANGING for writing: $!\n";
		print OUT $xsl or die "Failed to write $CHANGING: $!\n";
		close OUT or die "Failed to close $CHANGING: $!\n";

		$res = GET($uri) or die "Failed GET the [$uri]\n";
		$res->code eq 200 or die "The status is @{[ $res->code ]}, not good\n";
		$body = $res->content;
		my ($server_id, $outi) = ($body =~ m!pid \[(\d+)\] (\d+)!);
		$server_id or die "Failed to get pid from the server, got $body\n";
		$outi eq $i or die "Failed to get correct output, got $body\n";
		if (not exists $server_pids{$server_id}) {
			$server_pids{$server_id} = $body;
		} elsif ($server_pids{$server_id} eq $body) {
			die "Got the same body, so the same stylesheet was reused\n";
		} else {
			print "# Stylesheet changed ok\n";
			$changing_ok = 'yes';
			return 1;
		}
		return;
	};
	last if $ret;
	if ($@) {
		my $out = $@;
		$out =~ s/^/# /mg;
		print $out;
		$changing_ok = 'no';
		last;
	}
	sleep 1;
}

if ($changing_ok eq 'skip') {
	SKIP: {
		skip "Tried multiple times but failed to hit the same
		server to check how it handles changes in stylesheets.", 1;
	}
} elsif ($changing_ok eq 'no') {
	ok(0, "Will we notice when the stylesheet changes?");
} elsif ($changing_ok eq 'yes') {
	ok(1, "We notice changes in stylesheets code ok.");
} else {
	ok(0, "Some strange problem with the test suite.");
}

}

SKIP: {

skip "Cookies are not passed through proxy.", 25 if $main::location =~ /proxy/;

use HTTP::Cookies;
my $jar = new HTTP::Cookies;
$ua->cookie_jar($jar);

ok(1, $uri = "http://$hostport/$main::location/cookies.xml");
$request = new HTTP::Request GET => $uri;
$res = $ua->request($request);
ok($res, 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');

$body = $res->content;
is($body, <<EOF, "GET /$main::location/cookies.xml should process the body of the request");
<?xml version="1.0"?>
<cookies>
	<session>no session</session>
</cookies>
EOF

ok(1, $uri = "http://$hostport/$main::location/cookies.xml?login=123");
$request = new HTTP::Request GET => $uri;
$res = $ua->request($request);
ok($res, 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');

$body = $res->content;
is($body, <<EOF, "GET /$main::location/cookies.xml should process the body of the request");
<?xml version="1.0"?>
<cookies>
	<login>123</login>
	<session>logged in 123</session>
</cookies>
EOF

ok(1, $uri = "http://$hostport/$main::location/cookies.xml");
$request = new HTTP::Request GET => $uri;
$res = $ua->request($request);
ok($res, 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');

$body = $res->content;
is($body, <<EOF, "GET /$main::location/cookies.xml should process the body of the request");
<?xml version="1.0"?>
<cookies>
	<session>running 123</session>
</cookies>
EOF

ok(1, $uri = "http://$hostport/$main::location/cookies.xml?logout=1");
$request = new HTTP::Request GET => $uri;
$res = $ua->request($request);
ok($res, 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');

$body = $res->content;
is($body, <<EOF, "GET /$main::location/cookies.xml should process the body of the request");
<?xml version="1.0"?>
<cookies>
	<session>logged out 123</session>
</cookies>
EOF

ok(1, $uri = "http://$hostport/$main::location/cookies.xml");
$request = new HTTP::Request GET => $uri;
$res = $ua->request($request);
ok($res, 'Did we get HTTP::Response?');
is($res->code, 200, "Test the response code");
is($res->header('Content-Type'), 'text/xml', 'The data should be text/xml');

$body = $res->content;
is($body, <<EOF, "GET /$main::location/cookies.xml should process the body of the request");
<?xml version="1.0"?>
<cookies>
	<session>no session</session>
</cookies>
EOF

}

1;

