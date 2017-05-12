use Test::More;
use Test::Mojo;
use strict;
use warnings;
use Data::Dumper;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is('This is t::MojoTestServer');

$t->get_ok( '/vars.php' )->status_is(200);
my $content = $t->tx->res->body;
ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );
ok( $content =~ /_POST = array *\(\s*\)/, '$_POST is empty' );
ok( $content =~ /_REQUEST = array *\(\s*\)/, '$_REQUEST is empty' );
ok( $content =~ /_SERVER = array/ &&
    $content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
ok( $content =~ /_ENV = array/ &&
    $content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


$t->post_ok( '/vars.php' => form => { abc => 123, def => 456 } );
$t->status_is(200);
$content = $t->tx->res->body;
ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );
ok( $content !~ /_POST = array *\(\s*\)/, '$_POST not empty' );
ok( $content =~ /_POST.*abc.*=.*123.*_REQUEST/s, '$_POST["abc"] ok');
ok( $content =~ /_POST.*def.*=.*456.*_REQUEST/s, '$_POST["def"] ok');
ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
ok( $content =~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
    $content =~ /_REQUEST.*def.*=.*456.*_SERVER/s, '$_REQUEST mimics $_POST' );
ok( $content =~ /_SERVER = array/ &&
    $content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
ok( $content =~ /_ENV = array/ &&
    $content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


$t->post_ok( '/vars.php', form => { abc => [ 123, 789 ] , def => 456 } );
$t->status_is(200);
$content = $t->tx->res->body;

#    # When PHP receives a duplicate param name, it ignores all values
#    # except the last value.
#    $response = request POST 'http://localhost/vars.php', [#
#	abc => 123,
#	def => 456,
#	abc => 789
#    ];

ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );
ok( $content !~ /_POST = array *\(\s*\)/, '$_POST not empty' ); 
ok( $content !~ /_POST.*abc.*=.*123.*_REQUEST/s,
    'lost first val for $_POST["abc"]');
ok( $content =~ /_POST.*abc.*=.*789.*_REQUEST/s,
    'got last val for $_POST["abc"]');
ok( $content =~ /_POST.*def.*=.*456.*_REQUEST/s, '$_POST["def"] ok');
ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
    $content =~ /_REQUEST.*abc.*=.*789.*_SERVER/s &&
    $content =~ /_REQUEST.*def.*=.*456.*_SERVER/s, '$_REQUEST mimics $_POST' );
ok( $content =~ /_SERVER = array/ &&
    $content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
ok( $content =~ /_ENV = array/ &&
    $content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );

$t->post_ok( '/vars.php', form => { 'foo[x]', 1, 'foo[y]', 2, 'foo[z]', 3 } );
$t->status_is(200);

#    # When PHP receives a param name like  foo[bar] , it creates an 
#    # associative array param named foo with key bar.
#    $response = request POST 'http://localhost/vars.php', [
#	'foo[x]' => 1,
#	'foo[y]' => 2,
#	'foo[z]' => 3
#    ];

$content = $t->tx->res->body;

ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );

ok( $content !~ /_POST = array *\(\s*\)/, '$_POST not empty' ); 
my $z = $content =~ /_POST.*foo(.*)\$_REQUEST/s;
my $foo = $1;
ok( $z, '$_POST["foo"] was set' );
ok( $foo =~ /array/, '$_POST["foo"] was set to a PHP array' );
ok( $foo =~ /x.*1/, '$_POST["foo"]["x"] was set' );
ok( $foo =~ /y.*2/, '$_POST["foo"]["y"] was set' );
ok( $foo =~ /z.*3/, '$_POST["foo"]["z"] was set' );

ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
    $content =~ /_REQUEST.*foo.*array.*z.*3.*_SERVER/s,
    '$_REQUEST mimics $_GET' );
ok( $content =~ /_SERVER = array/ &&
    $content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
ok( $content =~ /_ENV = array/ &&
    $content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );



# 2-level hash
$t->post_ok( '/vars.php', form => { 'foo[4][x]' => 7,
				    'foo[4][y]' => 8, 'foo[5][z]' => 9 } );
$t->status_is(200);
$content = $t->tx->res->body;
ok( $content =~ /_GET = array *\(\s*\)/, '$_GET is empty' );

ok( $content !~ /_POST = array *\(\s*\)/, '$_POST not empty' ); 
$z = $content =~ /_POST.*foo(.*)\$_REQUEST/s;
$foo = $1;
ok( $z, '$_POST["foo"] was set' );
ok( $foo =~ /array/, '$_POST["foo"] was set to a PHP array' );
ok( $foo =~ /x.*7/, '$_POST["foo"]["x"] was set' );
ok( $foo =~ /y.*8/, '$_POST["foo"]["y"] was set' );
ok( $foo =~ /z.*9/, '$_POST["foo"]["z"] was set' );

ok( $foo =~ /array.*array.*array/s,
    '$_POST["foo"] looks like 2-level hash' );
ok( $foo =~ /array.*4.*array.*y.*8/s,
    '$_POST["foo"] looks like 2-level hash' );
ok( $foo =~ /array.*5.*array.*z.*9/s,
    '$_POST["foo"] looks like 2-level hash' );

ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
    $content =~ /_REQUEST.*foo.*array.*z.*9.*_SERVER/s,
    '$_REQUEST mimics $_GET' );
ok( $content =~ /_SERVER = array/ &&
    $content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
ok( $content =~ /_ENV = array/ &&
    $content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


# POST + query string
$t->post_ok( '/vars.php?get=7&foo=14',
	     form => { 'foo[r]' => 's', 'post' => 19,
		       'foo[t]' => 'u', 'foo[v]' => 'w' } );
$t->status_is(200);
$content = $t->tx->res->body;
#    $response = request POST 'http://localhost/vars.php?get=7&foo=14', [
#	'foo[r]' => 's',
#	'post' => 19,
#	'foo[t]' => 'u',
#	'foo[v]' => 'w',
#    ];

ok( $content =~ /_GET = array.*get.*7.*_POST/s, '$_GET contains "get"' );
ok( $content =~ /_REQUEST = array.*get.*7.*_SERVER/s,
    '$_REQUEST contains "get" from $_GET' );
ok( $content =~ /_GET = array.*foo.*14.*_POST/s, '$_GET contains "foo"' );
ok( $content !~ /_REQUEST = array.*foo.*14.*_SERVER/s, 
    '$_REQUEST doesn\'t contain "foo" from $_GET' );

ok( $content =~ /_POST = array.*post.*19.*_REQUEST/s,
    '$_POST contains "post"' );
ok( $content =~ /_POST = .*foo.*array.*r.*s.*_REQUEST/s &&
    $content =~ /_POST = .*foo.*array.*t.*u.*_REQUEST/s &&
    $content =~ /_POST = .*foo.*array.*v.*w.*_REQUEST/s,
    '$_POST contains array "foo"' );
ok( $content =~ /_REQUEST = array.*post.*19.*_SERVER/s,
    '$_REQUEST contains "post"' );
ok( $content =~ /_REQUEST = .*foo.*array.*r.*s.*_SERVER/s &&
    $content =~ /_REQUEST = .*foo.*array.*t.*u.*_SERVER/s &&
    $content =~ /_REQUEST = .*foo.*array.*v.*w.*_SERVER/s,
    '$_REQUEST contains array "foo"' );


$t->post_ok( '/vars.php?get=14&foo=77',
	     form => { 'foo[]' => [ '567', '789', '678' ],
		       post => 36 } );
$t->status_is(200);
#    $response = request POST 'http://localhost/vars.php?get=14&foo=77', [
#	'foo[]' => '567',
#	'post' => 36,
#	'foo[]' => '789',
#	'foo[]' => '678',
#    ];
#    ok( $response, 'response post+get ok' );
#    $content = eval { $response->content };
$content = $t->tx->res->body;

ok( $content =~ /_GET = array.*get.*14.*_POST/s, '$_GET contains "get"' );
ok( $content =~ /_REQUEST = array.*get.*14.*_SERVER/s,
    '$_REQUEST contains "get" from $_GET' );
ok( $content =~ /_GET = array.*foo.*77.*_POST/s, '$_GET contains "foo"' );
ok( $content !~ /_REQUEST = array.*foo.*77.*_SERVER/s, 
    '$_REQUEST doesn\'t contain "foo" from $_GET' );

ok( $content =~ /_POST = array.*post.*36.*_REQUEST/s,
    '$_POST contains "post"' );
ok( $content =~ /_POST = .*foo.*array.*0.*567.*_REQUEST/s &&
    $content =~ /_POST = .*foo.*array.*1.*789.*_REQUEST/s &&
    $content =~ /_POST = .*foo.*array.*2.*678.*_REQUEST/s,
    '$_POST contains array "foo"' );
ok( $content =~ /_REQUEST = array.*post.*36.*_SERVER/s,
    '$_REQUEST contains "post"' );
ok( $content =~ /_REQUEST = .*foo.*array.*0.*567.*_SERVER/s &&
    $content =~ /_REQUEST = .*foo.*array.*2.*678.*_SERVER/s &&
    $content =~ /_REQUEST = .*foo.*array.*1.*789.*_SERVER/s,
    '$_REQUEST contains array "foo"' )
or diag $content;

done_testing();
