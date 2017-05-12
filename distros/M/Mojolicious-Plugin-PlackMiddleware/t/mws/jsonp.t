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

use Test::More tests => 16;

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('SomeApp');
    $t->get_ok('/hash')
        ->status_is(200)
        ->header_is('Content-Type', 'application/json;charset=UTF-8')
        ->content_is(q({"foo":"bar"}));
    $t->get_ok('/hash?json.p=foo')
        ->status_is(200)
        ->header_is('Content-Type', 'text/javascript')
        ->content_is(q(/**/foo({"foo":"bar"})));
    $t->get_ok('/array')
        ->status_is(200)
        ->header_is('Content-Type', 'application/json;charset=UTF-8')
        ->content_is(q(["hoo","bar"]));
    $t->get_ok('/array?json.p=foo')
        ->status_is(200)
        ->header_is('Content-Type', 'text/javascript')
        ->content_is(q(/**/foo(["hoo","bar"])));
}
    {
        package SomeApp;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                JSONP => {callback_key => 'json.p'},
            ]);
            
            $self->routes->route('/hash')->to(cb => sub{
                my $json = {foo => 'bar'};
                $_[0]->render(json => $json);
            });
            $self->routes->route('/array')->to(cb => sub{
                my $json = ['hoo', 'bar'];
                $_[0]->render(json => $json);
            });
        }
    }

1;

__END__
