#!/usr/bin/perl 

use warnings;
$^W = 1;
use strict;

use Apache::Test ':withtestmore';
use Test::More;

use Apache::TestConfig;
use Apache::TestRequest qw(GET);

plan tests => 8;

my ($res, $body);

$res = GET '/dir/';
$body = $res->content;
is($body, <<EOF, "GET /dir/ should give us the /dir/index.html");
<html>
<body>
<p>Body of the index.html.</p>
</body>
</html>
EOF

$res = GET '/dir/index.html';
$body = $res->content;
is($body, <<EOF, "So should /dir/index.html");
<html>
<body>
<p>Body of the index.html.</p>
</body>
</html>
EOF

$res = GET '/dir';
$body = $res->content;
is($body, <<EOF, "And /dir without trailing slash");
<html>
<body>
<p>Body of the index.html.</p>
</body>
</html>
EOF

$res = GET '/my.html';
$body = $res->content;
is($body, <<EOF, "The same result for GET /my.html");
<html>
<body>
<p>Paragraph.</p>
</body>
</html>
EOF

$res = GET '/file';
$body = $res->content;
is($body, "Krtek.\n", "GET /file should give us the text file.");

$res = GET '/nonexistent';
is($res->code, 404, "The URL should not exist");
is($res->header('Content-Type'), 'text/html; charset=iso-8859-1', 'The error message content type');
$body = $res->content;
is($body, <<EOF, "GET /nonexistent should give us the 404 message.");
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL /nonexistent was not found on this server.</p>
</body></html>
EOF



