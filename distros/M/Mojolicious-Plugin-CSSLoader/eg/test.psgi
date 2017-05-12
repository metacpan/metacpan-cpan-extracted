#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', '../lib';
use Mojolicious::Lite;

plugin('CSSLoader', { base => '/css' });

any '/' => sub {
    my $self = shift;

    $self->render( 'default' );
};

any '/hello' => \&hello;

sub hello {
    my $self = shift;

    $self->render( 'hello' );
}

any '/no' => sub { shift->render( 'nofile' ) };

app->start;

__DATA__
@@ default.html.ep
% css_load( 'css_file.css' );

@@ hello.html.ep
% css_load( 'test.css', {no_base => 1} );
<html>
<body>
  <div><test /></div>
</body>
</html>

@@ nofile.html.ep
% css_load( '$(document).ready( function() { alert("test") } )', {no_file => 1} );

