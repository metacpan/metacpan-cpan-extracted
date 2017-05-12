#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::BootstrapAlerts';

## Webapp START

plugin('BootstrapAlerts');

any '/hello' => \&hello;

sub hello {
    my $self = shift;

    $self->notify( 'success', 'message2' );
    $self->notify( 'error', [qw/item1 item2/], { ordered_list => 1 } );
    $self->render( 'default' );
}

## Webapp END

my $t = Test::Mojo->new;

my $hello_check = qq~
                <div class="alert alert-dismissable alert-success">
                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                    message2
                </div>
            
                <div class="alert alert-dismissable alert-danger">
                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                    <ol><li>item1</li><li>item2</li></ol>
                </div>
            
~;

$t->get_ok( '/hello' )->status_is( 200 )->content_is( $hello_check );

done_testing();

__DATA__
@@ default.html.ep
%= notifications()
