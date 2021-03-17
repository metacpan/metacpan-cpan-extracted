package Template_Basic;
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use utf8;
use FindBin;

BEGIN {
    $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = 1;
    $ENV{MOJO_IOWATCHER}  = 'Mojo::IOWatcher';
    $ENV{MOJO_MODE}       = 'development';
}

use Test::More tests => 6;

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('SomeApp');
    $t->get_ok('/status/500.html')
        ->status_is(500)
        ->content_like(qr'fancy 500');
    $t->get_ok('/status/404.html')
        ->status_is(404)
        ->content_like(qr'fancy 404');
}
    {
        package SomeApp;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                ErrorDocument => {
                    500 => "$FindBin::Bin/errors/500.html"
                },
                ErrorDocument => {
                    404 => "/errors/404.html",
                    subrequest => 1,
                },
                Static => {
                    path => qr{^/errors},
                    root => $FindBin::Bin
                },
            ]);
            
            $self->routes->any('/*')->to(cb => sub{
                my $c = shift;
                my $status = ($c->req->url->path =~ m!status/(\d+)!)[0] || 200;
                $c->render(text => "Error: $status");
                $c->rendered($status);
            });
        }
    }

1;

__END__
