#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use File::Basename;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CSSLoader';

## Webapp START

my $dir = dirname( __FILE__ ) || '.';
app->static->paths([ "$dir/public" ]);

plugin('CSSLoader');

any '/'      => sub { shift->render( 'default' ) };
any '/hello' => sub {
    my $self = shift;

    $self->css_load( 'tester.css', { check => 1 } );
    $self->css_load( 'tester2.css', { check => 1 } );
    $self->render( 'default' );
};

## Webapp END

my $t = Test::Mojo->new;

my $base_check  = qq~<link rel="stylesheet" href="test.css"/><body>

<h2>Test</h2>
</body>
~;
my $hello_check  = qq~<link rel="stylesheet" href="tester.css"/>
<link rel="stylesheet" href="test.css"/><body>

<h2>Test</h2>
</body>
~;

$t->get_ok( '/' )->status_is( 200 )->content_is( $base_check );
$t->get_ok( '/hello' )->status_is( 200 )->content_is( $hello_check );

done_testing();

__DATA__
@@ default.html.ep
<body>
% css_load( 'test.css', {check => 1} );

<h2>Test</h2>
</body>

@@ tester.css
.test {
    color: white;
}

