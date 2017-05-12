#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::BootstrapAlerts';

## Webapp START

plugin('BootstrapAlerts');

any '/' => sub {
    my $self = shift;

    $self->notify( 'success', 'message' );
    $self->render( 'default' );
};

any '/hello' => \&hello;

sub hello {
    my $self = shift;

    $self->notify( 'success', 'message2' );
    $self->notify( 'error', [qw/item1 item2/] );
    $self->render( 'default' );
}

## Webapp END

my $t = Test::Mojo->new;

my $base_check = qq~
                <div class="alert alert-dismissable alert-success">
                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                    message
                </div>
            
~;

my $hello_check = qq~
                <div class="alert alert-dismissable alert-success">
                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                    message2
                </div>
            
                <div class="alert alert-dismissable alert-danger">
                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                    <ul><li>item1</li><li>item2</li></ul>
                </div>
            
~;

$t->get_ok( '/' )->status_is( 200 )->content_is( $base_check );
$t->get_ok( '/hello' )->status_is( 200 )->content_is( $hello_check );

done_testing();

__DATA__
@@ default.html.ep
%= notifications()
