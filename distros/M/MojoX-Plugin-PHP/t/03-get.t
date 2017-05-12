use Test::More;
use Test::Mojo;
use Data::Dumper;
use strict;
use warnings;

$Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is('This is t::MojoTestServer');

# vars.php: dump PHP $_GET,$_POST,$_REQUEST,$_SERVER,$_ENV,$_COOKIE,$_FILES
$t->get_ok('/vars.php')->status_is(200, 'data returned for vars.php')
    ->content_like( qr/_GET = array *\(\s*\)/, '$_GET is empty' )
    ->content_like( qr/_POST = array *\(\s*\)/, '$_POST is empty' )
    ->content_like( qr/_REQUEST = array *\(\s*\)/, '$_REQUEST is empty' )
    ->content_like( qr/_SERVER =/, '$_SERVER spec found' )
    ->content_unlike( qr/_SERVER = array *\(\s*\)/, '$_SERVER not empty')
    ->content_like( qr/_ENV =/, '$_ENV spec found' )
    ->content_unlike( qr/_ENV = array *\(\s*\)/, '$_ENV not empty')
    ->content_like( qr/_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' )
    ->content_like( qr/_GET = array *\(\s*\)/, '$_GET is empty' );

$t->get_ok('/vars.php?abc=123&def=456')
    ->status_is(200, 'vars.php request with query');
my $content = $t->tx->res->body;
ok( $content !~ /_GET = array *\(\s*\)/, '$_GET not empty' );
ok( $content =~ /_GET.*abc.*=.*123.*_POST/s, '$_GET["abc"] ok');
ok( $content =~ /_GET.*def.*=.*456.*_POST/s, '$_GET["def"] ok');
ok( $content =~ /_POST = array *\(\s*\)/, '$_POST is empty' );
ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
ok( $content =~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
    $content =~ /_REQUEST.*def.*=.*456.*_SERVER/s, '$_REQUEST mimics $_GET'
    );
ok( $content =~ /_SERVER = array/ &&
    $content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
ok( $content =~ /_ENV = array/ &&
    $content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );



# when PHP receives a duplicate value, it should ignore all values 
# except the last one
$t->get_ok('/vars.php?abc=123&def=456&abc=789')
    ->status_is(200, 'vars.php request (2) query');
$content = $t->tx->res->body;
ok( $content !~ /_GET = array *\(\s*\)/, '$_GET not empty' ); 
ok( $content !~ /_GET.*abc.*=.*123.*_POST/s, 'lost first val for $_GET["abc"]');
ok( $content =~ /_GET.*abc.*=.*789.*_POST/s, 'got last val for $_GET["abc"]');
ok( $content =~ /_GET.*def.*=.*456.*_POST/s, '$_GET["def"] ok');
ok( $content =~ /_POST = array *\(\s*\)/, '$_POST is empty' );
ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
    $content =~ /_REQUEST.*abc.*=.*789.*_SERVER/s &&
    $content =~ /_REQUEST.*def.*=.*456.*_SERVER/s, '$_REQUEST mimics $_GET' );
ok( $content =~ /_SERVER = array/ &&
    $content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
ok( $content =~ /_ENV = array/ &&
    $content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


# When PHP receives a param name like  foo[bar] , it creates an 
# associative array param named foo with key bar.
$t->get_ok('/vars.php?foo[x]=1&foo[y]=2&foo[z]=3')->status_is(200);
$content = $t->tx->res->body;
ok( $content !~ /_GET = array *\(\s*\)/, '$_GET not empty' ); 
my $z = $content =~ /_GET.*foo(.*)\$_POST/s;
my $foo = $1;
ok( $z, '$_GET["foo"] was set' );
ok( $foo =~ /array/, '$_GET["foo"] was set to a PHP array' );
ok( $foo =~ /x.*1/, '$_GET["foo"]["x"] was set' );
ok( $foo =~ /y.*2/, '$_GET["foo"]["y"] was set' );
ok( $foo =~ /z.*3/, '$_GET["foo"]["z"] was set' );
ok( $content =~ /_POST = array *\(\s*\)/, '$_POST is empty' );
ok( $content !~ /_REQUEST = array *\(\s*\)/, '$_REQUEST not empty' );
ok( $content !~ /_REQUEST.*abc.*=.*123.*_SERVER/s &&
    $content =~ /_REQUEST.*foo.*array.*z.*3.*_SERVER/s,
    '$_REQUEST mimics $_GET' );
ok( $content =~ /_SERVER = array/ &&
    $content !~ /_SERVER = array *\(\s*\)/, '$_SERVER not empty' );
ok( $content =~ /_ENV = array/ &&
    $content !~ /_ENV = array *\(\s*\)/, '$_ENV not empty' );
ok( $content =~ /_COOKIE = array *\(\s*\)/, '$_COOKIE is empty' );


# can we edit the stash?
$t->app->config->{'MojoX::Template::PHP'}{php_var_preprocessor} = sub {
    $_[0]->{stash1} = "stash variable 1";
    $_[0]->{stash2} = "STASH VARIABLE 2";
};
$t->get_ok('/stash.php')->status_is(200)
    ->content_like( qr/\$stash1 = stash variable 1/,
		    'var preprocessor updates PHP global var')
    ->content_like( qr/\$stash2 = STASH VARIABLE 2/ );


done_testing();
