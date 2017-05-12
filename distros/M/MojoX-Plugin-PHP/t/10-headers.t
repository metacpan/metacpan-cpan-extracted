use Test::More;
use Test::Mojo;
use strict;
use warnings;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is( 'This is t::MojoTestServer' );

$t->post_ok( '/headers.php', form => { abc => 123, def => 456 } )
    ->status_is(200);
my $content = $t->tx->res->body;
my $headers = $t->tx->res->headers;

my $names = $headers->names;
ok( (grep /X-header-\w+/, @$names) == 2, 'headers from PHP were set in Mojo' );
ok( $headers->header('X-header-abc') eq '123',
    'header 1 from PHP was set in Mojo with correct value' );
ok( $headers->header('X-header-def') eq '456',
    'header 2 from PHP was set in Mojo with correct value' );


# header_compute.php: deliver a message to Perl through a header callback.
#   Perl will set a global variable in PHP and header_compute.php
#   will output it.
$t->get_ok('/header_compute.php')->status_is(200);

$content = $t->tx->res->body;
ok( $content,  'got content for header_compute.php' );
ok( $content =~ /begin result/, 'found result begin marker' );
ok( $content =~ /end result/, 'found result end marker' );
ok( $content !~ /Input/, 'post had no requests, so there are no results' );

$t->post_ok( '/header_compute.php',
	     form => {
		 expr1 => 'exp(5.5 * log(14.14))',
		 expr6 => '$INC{"PHP.pm"}'
	     } )->status_is(200);
$content = $t->tx->res->body;

ok( $content,  'got content for header_compute.php' );
ok( $content =~ /begin result/, 'found result begin marker' );
ok( $content =~ /end result/, 'found result end marker' );
ok( $content =~ /Input \# 1/, 'echoed expression #1' );
ok( $content =~ /Input \# 6/, 'echoed expression #6' );
ok( $content !~ /Input \# 2/, 'no expression #2 to echo' );
ok( $content !~ /Input \# 5/, 'no expression #5 to echo' );
ok( $content !~ /Input \# 8/, 'no expression #8 to echo' );
my ($result1) = $content =~ /Output\# 1:\s+(.*)/;
my ($result6) = $content =~ /Output\# 6:\s+(.*)/;

ok( $result1, 'got result for expression #1' );
ok( $result6, 'got result for expression #6' );
ok( abs($result1 - (14.14**5.5)) < 1.0E-2,
    'result #1 was correct expression for 14.14**5.5' )
    or diag 14.14**5.5;
ok( $result6 =~ m{/PHP\.pm} , 'result #6 looks correct' );

if ($PHP::VERSION >= 0.15) {

    $t->get_ok('/headers2.php')->status_is(200);
    $content = $t->tx->res->body;
    my $response = $t->tx->res->headers;

    ok( ref($response->header("foo")) ne 'ARRAY' &&
	$response->header("foo") eq 'baz',
	'default header callback respects $replace=true' );

    my $header_123 = $response->header("123");
    ok( (ref($header_123) eq 'ARRAY' &&
	 $header_123->[0] eq '456' &&
	 $header_123->[1] eq '789') ||
	(ref($header_123) ne 'ARRAY' &&
	 $header_123 eq '456, 789') ,
	'default header callback respects $replace=false' )
	or diag Dumper($header_123);

    ok( ref($response->header('abc')) ne 'ARRAY' &&
	$response->header("abc") eq 'jkl',
	'default header callback default $replace is true' );
} else {
    diag "PHP 0.15 required to test replace argument in header callback";
}

done_testing();
