#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use File::Basename;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::JSLoader';

## Webapp START

my $dir = dirname( __FILE__ ) || '.';
app->static->paths([ "$dir/public" ]);

plugin('JSLoader');

any '/'      => sub { shift->render( 'default' ) };
any '/hello' => sub {
    my $self = shift;

    $self->js_load( 'tester.js', { check => 1 } );
    $self->render( 'default' );
};

## Webapp END

my $t = Test::Mojo->new;

my $base_check  = qq~<body>

<h2>Test</h2>
</body>
~;
my $hello_check  = qq~<body>

<h2>Test</h2>
<script type="text/javascript" src="tester.js"></script></body>
~;

$t->get_ok( '/' )->status_is( 200 )->content_is( $base_check );
$t->get_ok( '/hello' )->status_is( 200 )->content_is( $hello_check );

done_testing();

__DATA__
@@ default.html.ep
<body>
% js_load( 'js_file.js', {check => 1} );

<h2>Test</h2>
</body>

@@ tester.js
$(document).ready( function(){
  alert('tester.js');
});
