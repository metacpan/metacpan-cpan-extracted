#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use File::Basename;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::MoreHTMLHelpers';

## Webapp START

plugin('MoreHTMLHelpers');

any '/:color' => sub {
    my $self = shift;

    my $textcolor = $self->textcolor( '#' . $self->param('color') );
    $self->render( text => $textcolor );
};

## Webapp END

my %colors = (
  '000'    => '#ffffff',
  '000000' => '#ffffff',
  'fff'    => '#000000',
  'ffffff' => '#000000',
  'FFF'    => '#000000',
  'FFFFFF' => '#000000',
  '000274' => '#ffffff',
  '119648' => '#ffffff',
  '11a6d8' => '#000000',
  'd1acd8' => '#000000',
  '808080' => '#ffffff',
  'cdcdcd' => '#000000',
);

my $t = Test::Mojo->new;

for my $color ( keys %colors ) {
    $t->get_ok( '/' . $color )->status_is( 200 )->content_is( $colors{$color}, '#' . $color );
}

done_testing();

