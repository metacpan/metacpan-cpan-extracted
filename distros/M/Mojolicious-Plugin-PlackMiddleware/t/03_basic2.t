package Template_Basic;
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use utf8;

BEGIN {
    $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = 1;
    $ENV{MOJO_IOWATCHER}  = 'Mojo::IOWatcher';
    $ENV{MOJO_MODE}       = 'development';
}

use Test::More tests => 6;

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('SomeApp');
    $t->get_ok('/default')
        ->status_is(200)
        ->content_is('<hook1><hook2>default</hook2></hook1>');
    $t->get_ok('/non_exits')
        ->status_is(200)
        ->content_is('<hook1><hook2>default</hook2></hook1>');
}

    {
        package SomeApp;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->hook(around_dispatch => sub {
                my ($next, $c) = @_;
                $next->();
                my $org = $c->res->body;
                $c->res->body("<hook1>$org</hook1>");
            });
            
            $self->plugin('plack_middleware', [
                'TestFilter'
            ]);
            
            $self->hook(around_dispatch => sub {
                my ($next, $c) = @_;
                $next->();
                my $org = $c->res->body;
                $c->res->body("<hook2>$org</hook2>");
            });
            
            $self->routes->route('/default')->to(cb => sub{
                $_[0]->render(text => 'default');
            });
        }
    }

package Plack::Middleware::TestFilter;
use strict;
use warnings;
use base qw( Plack::Middleware );

sub call {
    my ($self, $env) = @_;
    my $res = $self->app->($env);
    
    if ($res->[0] == 404) {
        local $env->{PATH_INFO} = 'default';
        return $self->app->($env);
    }
    
    return $res;
}

1;

__END__
