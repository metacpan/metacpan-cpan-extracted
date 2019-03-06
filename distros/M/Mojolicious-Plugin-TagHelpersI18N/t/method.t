#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use File::Basename;

use lib dirname( __FILE__ );

use utf8;

use_ok 'Mojolicious::Plugin::TagHelpersI18N';

sub Mojolicious::Lite::fail_with {};

## Webapp START

plugin('I18N' => {namespace => 'Local::I18N', default => 'de'});
plugin('TagHelpersI18N' => { method => 'translate' });

app->helper( translate => sub {
    my $c = shift;
    $c->l( @_ );
});

any '/'      => sub {
    my $self = shift; 
    $self->languages( $self->param('lang') || 'de' );
    $self->render( 'default' );
};

any '/no' => sub {
    my $self = shift;
    $self->render;
};

## Webapp END

my $t = Test::Mojo->new;

my $base_check  = qq~<select name="test"><option value="hello">Hallo</option><option value="test">test</option></select>\n~;
my $hello_check = qq~<select name="test"><option value="hello">hello</option><option value="test">test</option></select>\n~;
my $ru_check    = qq~<select name="test"><option value="hello">Алло</option><option value="test">тест</option></select>\n~;

$t->get_ok( '/' )->status_is( 200 )->content_is( $base_check );
$t->get_ok( '/no' )->status_is( 200 )->content_is( $hello_check );
$t->get_ok( '/?lang=ru' )->status_is( 200 )->content_is( $ru_check );

done_testing();

__DATA__
@@ default.html.ep
%= select_field 'test' => [qw/hello test/];

@@ no.html.ep
%= select_field 'test' => [qw/hello test/], no_translation => 1;

