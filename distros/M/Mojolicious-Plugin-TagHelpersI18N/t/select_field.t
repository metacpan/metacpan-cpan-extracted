#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use File::Basename;
use Capture::Tiny qw(capture_stderr);

use lib dirname(__FILE__);

use utf8;

use_ok 'Mojolicious::Plugin::TagHelpersI18N';

sub Mojolicious::Lite::fail_with {};

## Webapp START

plugin('I18N' => {namespace => 'Local::I18N', default => 'de'});
plugin('TagHelpersI18N');

any '/' => sub {
    my $self = shift; 
    $self->languages( $self->param('lang') || 'de' );
    $self->render( 'default' );
};

any '/no' => sub {
    my $self = shift;
    $self->render;
};

any '/:type' => sub {
    my $self = shift; 
    $self->languages( $self->param('lang') || 'de' );
    $self->render( $self->param('type') );
};

## Webapp END

my $t = Test::Mojo->new;

my $base_check  = qq~<select name="test"><option value="hello">Hallo</option><option value="test">test</option></select>\n~;
my $hello_check = qq~<select name="test"><option value="hello">hello</option><option value="test">test</option></select>\n~;
my $ru_check    = qq~<select name="test"><option value="hello">Алло</option><option value="test">тест</option></select>\n~;

$t->get_ok( '/' )->status_is( 200 )->content_is( $base_check );
$t->get_ok( '/no' )->status_is( 200 )->content_is( $hello_check );
$t->get_ok( '/?lang=ru' )->status_is( 200 )->content_is( $ru_check );
$t->get_ok( '/array' )->status_is( 200 )->content_is( $base_check );

{
    my $stderr = capture_stderr {
        $t->get_ok( '/hash' )->status_is( 200 )->content_is(
            '<select name="test"><optgroup label=""><option value="hello">Hallo</option><option value="test">test</option></optgroup></select>
'       );
    };

    like $stderr, qr/hash references are DEPRECATED in favor of Mojo::Collection/;
}

{
    my $stderr = capture_stderr {
        $t->get_ok( '/hash2' )->status_is( 200 )->content_is(
            '<select name="test"><optgroup label=""><option value="hello">Hallo</option><option value="test">test</option></optgroup></select>
'       );
    };

    like $stderr, qr/hash references are DEPRECATED in favor of Mojo::Collection/;
}

$t->get_ok( '/collection' )->status_is( 200 )->content_is( 
    '<select name="test"><optgroup label="Test"><option value="hello">Hallo</option><option value="test">test</option></optgroup></select>
'
);

$t->get_ok( '/other_object' )->status_is( 200 )->content_is( 
    '<select name="test"><option value="template other_object.html.ep from DATA section">template other_object.html.ep from DATA section</option></select>
'
);

$t->get_ok( '/array?test=hallo' )->status_is( 200 )->content_is( $base_check );

done_testing();

__DATA__
@@ default.html.ep
%= select_field 'test' => [qw/hello test/];

@@ no.html.ep
%= select_field 'test' => [qw/hello test/], no_translation => 1;

@@ array.html.ep
%= select_field 'test' => [[ 'hello', 'hello'], 'test'];

@@ hash.html.ep
%= select_field 'test' => [{ 'hello' => 'hello', 'test' => 'test'}];

@@ collection.html.ep
%= select_field 'test' => [c( Test => [ 'hello', 'test'])];

@@ hash2.html.ep
%= select_field 'test' => { 'hello' => 'hello', 'test' => 'test'};

@@ other_object.html.ep
%= select_field 'test' => [Mojo::File->new(__FILE__)];

