#!/usr/bin/perl

use strict;
use warnings;

use Mojolicious::Lite;
use FindBin;

use lib $FindBin::Bin;

plugin('I18N' => { namespace => 'Local::I18N', default => 'de' } );
plugin('TagHelpersI18N');

any '/' => sub {
    my $self = shift;

    $self->languages( $self->param('lang') || 'de' );

    $self->render( 'default' );
};

any '/no' => sub { shift->render };

app->start;

__DATA__
@@ default.html.ep
%= select_field 'test' => [qw/hello test/];

@@ no.html.ep
%= select_field 'test' => [qw/hello test/], no_translation => 1;

