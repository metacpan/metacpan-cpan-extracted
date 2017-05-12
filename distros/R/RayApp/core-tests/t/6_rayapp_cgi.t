#!/usr/bin/perl -Tw
 
use Test::More tests => 16;

use warnings;
$^W = 1;
use strict;
use utf8;

BEGIN { chdir 't' if -d 't'; }

use_ok( 'IPC::Open3' );
use_ok( 'RayApp::CGI' );
my ($out, $err);

local (*WRTFH, *RDFH, *ERRFH);
delete @ENV{'PATH', 'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
undef $/;
my $PERL = $^X;
$PERL =~ /(.+)/ and $PERL = $1;
my $pid;

$ENV{PATH_TRANSLATED} = 'script1.xml';
$pid = IPC::Open3::open3(\*WRTFH, \*RDFH, \*ERRFH,
	$PERL, '-Mblib', '-MRayApp::CGI', '-e', 'RayApp::CGI::handler()');
close WRTFH;
$out = <RDFH>;
close RDFH;
$err = <ERRFH>;
close ERRFH;

is($out, <<'EOF', "Check the output of XML serialization");
Pragma: no-cache
Cache-control: no-cache
Status: 200
Content-Type: text/xml

<?xml version="1.0" standalone="yes"?>
<list>
	<students>
		<student>
			<lastname>Peter</lastname>
			<firstname>Wolf</firstname>
		</student>
		<student>
			<lastname>Brian</lastname>
			<firstname>Fox</firstname>
		</student>
		<student>
			<lastname>Leslie</lastname>
			<firstname>Child</firstname>
		</student>
		<student>
			<lastname>Barbara</lastname>
			<firstname>Bailey</firstname>
		</student>
		<student>
			<lastname>Russell</lastname>
			<firstname>King</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Johnson</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Shell</firstname>
		</student>
		<student>
			<lastname>Tim</lastname>
			<firstname>Jasmine</firstname>
		</student>
	</students>

	<program>
		<id>1523</id>
		<code>8234B</code>
		<name>&#x160;&#xED;len&#xE9; lan&#x11B;</name>
	</program>
</list>
EOF

$err = '' if not defined $err;
is($err, '', "Check the error output");

$ENV{PATH_TRANSLATED} = 'script1.html';
$pid = IPC::Open3::open3(\*WRTFH, \*RDFH, \*ERRFH,
	$PERL, '-I../../lib', '-MRayApp::CGI', '-e', 'RayApp::CGI::handler()');
close WRTFH;
binmode RDFH, ':utf8';
$out = <RDFH>;
close RDFH;
$err = <ERRFH>;
close ERRFH;

is($out, <<'EOF', "Check the output of HTML serialization");
Pragma: no-cache
Cache-control: no-cache
Status: 200
Content-Type: text/html; charset=UTF-8

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title></title>
</head>
<body>
<h1>A list of students</h1>
<p>
Study program:
<b>Šílené laně</b>
(<tt>8234B</tt>)
</p>
<ul>
		<li>Wolf Peter</li>
		<li>Fox Brian</li>
		<li>Child Leslie</li>
		<li>Bailey Barbara</li>
		<li>King Russell</li>
		<li>Johnson Michael</li>
		<li>Shell Michael</li>
		<li>Jasmine Tim</li>
	</ul>
</body>
</html>
EOF

$err = '' if not defined $err;
is($err, '', "Check the error output");

$ENV{PATH_TRANSLATED} = 'script1.html';
$pid = IPC::Open3::open3(\*WRTFH, \*RDFH, \*ERRFH,
	'../../bin/rayapp_cgi_wrapper');
close WRTFH;
binmode RDFH, ':utf8';
$out = <RDFH>;
close RDFH;
$err = <ERRFH>;
close ERRFH;

is($out, <<'EOF', "Check the output of HTML serialization");
Pragma: no-cache
Cache-control: no-cache
Status: 200
Content-Type: text/html; charset=UTF-8

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title></title>
</head>
<body>
<h1>A list of students</h1>
<p>
Study program:
<b>Šílené laně</b>
(<tt>8234B</tt>)
</p>
<ul>
		<li>Wolf Peter</li>
		<li>Fox Brian</li>
		<li>Child Leslie</li>
		<li>Bailey Barbara</li>
		<li>King Russell</li>
		<li>Johnson Michael</li>
		<li>Shell Michael</li>
		<li>Jasmine Tim</li>
	</ul>
</body>
</html>
EOF

$err = '' if not defined $err;
is($err, '', "Check the error output");

$ENV{PATH_TRANSLATED} = 'script1.html';
$pid = IPC::Open3::open3(\*WRTFH, \*RDFH, \*ERRFH,
	$PERL, '-I../../lib', '-MRayApp::CGIWrapper');
close WRTFH;
binmode RDFH, ':utf8';
$out = <RDFH>;
close RDFH;
$err = <ERRFH>;
close ERRFH;

is($out, <<'EOF', "Check the output of HTML serialization");
Pragma: no-cache
Cache-control: no-cache
Status: 200
Content-Type: text/html; charset=UTF-8

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title></title>
</head>
<body>
<h1>A list of students</h1>
<p>
Study program:
<b>Šílené laně</b>
(<tt>8234B</tt>)
</p>
<ul>
		<li>Wolf Peter</li>
		<li>Fox Brian</li>
		<li>Child Leslie</li>
		<li>Bailey Barbara</li>
		<li>King Russell</li>
		<li>Johnson Michael</li>
		<li>Shell Michael</li>
		<li>Jasmine Tim</li>
	</ul>
</body>
</html>
EOF

$err = '' if not defined $err;
is($err, '', "Check the error output");

$pid = IPC::Open3::open3(\*WRTFH, \*RDFH, \*ERRFH,
	$PERL, '-I../../lib', '-MRayApp::CGI', '-e', 'RayApp::CGI::handler',
	'script1.xml');
close WRTFH;
$out = <RDFH>;
close RDFH;
$err = <ERRFH>;
close ERRFH;

is($out, <<'EOF', "Check the XML output for target set on command line");
Pragma: no-cache
Cache-control: no-cache
Status: 200
Content-Type: text/xml

<?xml version="1.0" standalone="yes"?>
<list>
	<students>
		<student>
			<lastname>Peter</lastname>
			<firstname>Wolf</firstname>
		</student>
		<student>
			<lastname>Brian</lastname>
			<firstname>Fox</firstname>
		</student>
		<student>
			<lastname>Leslie</lastname>
			<firstname>Child</firstname>
		</student>
		<student>
			<lastname>Barbara</lastname>
			<firstname>Bailey</firstname>
		</student>
		<student>
			<lastname>Russell</lastname>
			<firstname>King</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Johnson</firstname>
		</student>
		<student>
			<lastname>Michael</lastname>
			<firstname>Shell</firstname>
		</student>
		<student>
			<lastname>Tim</lastname>
			<firstname>Jasmine</firstname>
		</student>
	</students>

	<program>
		<id>1523</id>
		<code>8234B</code>
		<name>&#x160;&#xED;len&#xE9; lan&#x11B;</name>
	</program>
</list>
EOF

$err = '' if not defined $err;
is($err, '', "No error output");


$ENV{PATH_TRANSLATED} = 'not_exist.html';
$pid = IPC::Open3::open3(\*WRTFH, \*RDFH, \*ERRFH,
	$PERL, '-I../../lib', '-MRayApp::CGIWrapper');
close WRTFH;
$out = <RDFH>;
close RDFH;
$err = <ERRFH>;
close ERRFH;

is($out, <<'EOF', "Check the 404 message");
Status: 404
Content-Type: text/plain

The requested URL was not found on this server.
EOF

$err = '' if not defined $err;
is($err, <<'EOF', "Check the error output");
RayApp::CGI: filename [not_exist.html] no DSD found
EOF

$ENV{PATH_TRANSLATED} = 'not_exist.html';
$pid = IPC::Open3::open3(\*WRTFH, \*RDFH, \*ERRFH,
	$PERL, '-I../../lib', '-MRayApp::CGIWrapper');
close WRTFH;
$out = <RDFH>;
close RDFH;
$err = <ERRFH>;
close ERRFH;

is($out, <<'EOF', "Check the 404 message");
Status: 404
Content-Type: text/plain

The requested URL was not found on this server.
EOF

$err = '' if not defined $err;
is($err, <<'EOF', "Check the error output");
RayApp::CGI: filename [not_exist.html] no DSD found
EOF

