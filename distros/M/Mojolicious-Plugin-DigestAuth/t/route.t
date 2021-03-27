use strict;
use warnings;
use lib 't';

use Test::More tests => 6;
use Test::Mojo;
use TestHelper;

package App;
use Mojo::Base 'Mojolicious';
    
sub startup
{
    my $self = shift;
    $self->plugin('digest_auth');
    
    my $r = $self->digest_auth('/admin', allow => TestHelper::users());	
    $r->_route('/:id')->to('controller#show');	
}

package App::Controller;
use Mojo::Base 'Mojolicious::Controller';

sub show { shift->render(text => 'In!') }

package main;

my $t = Test::Mojo->new;
$t->app(App->new);        
$t->get_ok('/admin/123')
    ->status_is(401)
    ->content_is('HTTP 401: Unauthorized');

$t->get_ok('/admin/123', build_auth_request($t->tx))
    ->status_is(200)
    ->content_is('In!');
