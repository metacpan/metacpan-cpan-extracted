#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::JSLoader';

## Webapp START

plugin('JSLoader');

any '/ie8' => sub { shift->render( 'ie8' ) };
any '/ie_gt8' => sub { shift->render( 'ie9' ) };
any '/default' => sub { shift->render( 'ie10' ) };

## Webapp END

#my $ie8 = Mojo::UserAgent->new( Mojo::UserAgent::Transactor->new );
#$ie8->transactor->name( 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; SLCC1; .NET CLR 1.1.4322)' );

my $test_ie8 = Test::Mojo->new;
$test_ie8->ua->transactor->name( 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; SLCC1; .NET CLR 1.1.4322)' );

my $test_ie9 = Test::Mojo->new;
$test_ie9->ua->transactor->name( 'Mozilla/5.0 (Windows; U; MSIE 9.0; Windows NT 9.0; en-US)' );

my $test_firefox = Test::Mojo->new;
$test_firefox->ua->transactor->name( 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:26.0) Gecko/20100101 Firefox/26.0' );

my $ie8_ie8_check  = qq~<body>
<script type="text/javascript" src="js_file.js"></script>
</body>
~;
my $ie8_non_ie8_check  = qq~<body>

</body>
~;

$test_ie8->get_ok( '/ie8' )->status_is( 200 )->content_is( $ie8_ie8_check );
$test_ie9->get_ok( '/ie8' )->status_is( 200 )->content_is( $ie8_non_ie8_check );
$test_firefox->get_ok( '/ie8' )->status_is( 200 )->content_is( $ie8_non_ie8_check );

$test_ie8->get_ok( '/ie_gt8' )->status_is( 200 )->content_is( $ie8_ie8_check );
$test_ie9->get_ok( '/ie_gt8' )->status_is( 200 )->content_is( $ie8_ie8_check );
$test_firefox->get_ok( '/ie_gt8' )->status_is( 200 )->content_is( $ie8_non_ie8_check );

$test_ie8->get_ok( '/default' )->status_is( 200 )->content_is( $ie8_non_ie8_check );
$test_ie9->get_ok( '/default' )->status_is( 200 )->content_is( $ie8_ie8_check );
$test_firefox->get_ok( '/default' )->status_is( 200 )->content_is( $ie8_ie8_check );

done_testing();

__DATA__
@@ ie8.html.ep
<body>
%= js_load( 'js_file.js', {inplace => 1, browser => { "Internet Explorer" => 8 } } );
</body>
@@ ie9.html.ep
<body>
%= js_load( 'js_file.js', {inplace => 1, browser => { "Internet Explorer" => 'gt 7' } } );
</body>
@@ ie10.html.ep
<body>
%= js_load( 'js_file.js', {inplace => 1, browser => { "Internet Explorer" => '!8', default => 1 } } );
</body>
