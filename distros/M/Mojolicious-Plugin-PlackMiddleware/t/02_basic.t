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

use Test::More tests => 56;

use File::Basename 'dirname';
local $ENV{MOJO_HOME} = dirname(__FILE__);

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('SomeApp');
    $t->get_ok('/index')
        ->status_is(200)
        ->header_is('Content-length', 18)
        ->content_is('original[filtered]');
    $t->get_ok('/css.css')
        ->status_is(200)
        ->header_is('Content-length', 13)
        ->content_is('css[filtered]');
}

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('SomeApp');
    local $SIG{ALRM} = sub { die "timeout\n" }; alarm 2;
    $t->tx($t->ua->get('/index',
        {'Content-Type' => 'multipart/form-data; boundary="abcdefg"'},
        "\x0d\x0a\x0d\x0acontent\x0d\x0a--abcdefg--\x0d\x0a")
    );
    $t->content_is('original[filtered]');
}

    {
        package SomeApp;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'TestFilter'
            ]);
            
            $self->routes->any('/index')->to(cb => sub{
                $_[0]->render(text => 'original');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('OnProcessTwice');
    $t->get_ok('/index1')
        ->status_is(200)
        ->content_is('index2');
}
    {
        package OnProcessTwice;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'InvokeAppTwice'
            ]);
            
            $self->routes->any('/index1')->to(cb => sub{
                $_[0]->reply->not_found;
            });
            $self->routes->any('/index2')->to(cb => sub{
                $_[0]->render(text => 'index2');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('FormData');
    $t->post_ok('/index' => form => {a => 'b'});
}
    {
        package FormData;
        use strict;
        use warnings;
        use base 'Mojolicious';
        use Test::More;
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'TestFilter'
            ]);
            
            $self->routes->any('/index')->to(cb => sub{
                my $content_type = $_[0]->req->headers->header('content-type');
                is($content_type, 'application/x-www-form-urlencoded', 'right content type');
                is($_[0]->req->body, 'a=b', 'req body set');
                $_[0]->render(text => 'original');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'development';
    my $t = Test::Mojo->new('FormDataMultipart');
    $t->post_ok('/index' => {'Content-Type' => 'multipart/form-data'} => form => {foo => 'bar'})
        ->status_is(200);
}
    {
        package FormDataMultipart;
        use strict;
        use warnings;
        use base 'Mojolicious';
        use Test::More;
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'TestFilter'
            ]);
            
            $self->routes->any('/index')->to(cb => sub{
                my $content_type = $_[0]->req->headers->header('content-type');
                like($content_type, qr{multipart/form-data}, 'right content type');
                is($_[0]->req->body_params->param('foo'), 'bar', 'right body param');
                $_[0]->render(text => 'original');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('ReqModified');
    $t->get_ok('/index')
        ->status_is(200)
        ->content_is('ok');
}
    {
        package ReqModified;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'TestFilter4'
            ]);
            
            $self->routes->any('/index.html')->to(cb => sub{
                $_[0]->render(text => 'ok');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('SomeApp2');
    $t->get_ok('/index')
        ->status_is(200)
        ->header_is('Content-length', 29)
        ->content_is('original[filtered2][filtered]');
}
    {
        package SomeApp2;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'TestFilter',
                'TestFilter2',
            ]);
            
            $self->routes->any('/index')->to(cb => sub{
                $_[0]->render(text => 'original');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('SomeApp3');
    $t->get_ok('/index')
        ->status_is(200)
        ->header_is('Content-length', 13)
        ->content_is('original[aaa]');
}
    {
        package SomeApp3;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'TestFilter3' => {tag => 'aaa'},
            ]);
            
            $self->routes->any('/index')->to(cb => sub{
                $_[0]->render(text => 'original');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('GrowLarge');
    $t->get_ok('/index')
        ->status_is(200)
        ->header_is('Content-length', 100001)
        ->content_like(qr/890$/);
}
    {
        package GrowLarge;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'GrowLargeFilter',
            ]);
            
            $self->routes->any('/index')->to(cb => sub{
                $_[0]->render(text => '1');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('HeadModified');
    $t->get_ok('/index')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=Shift_JIS')
        ->header_is('Content-length', 6)
        ->content_is('日本語');
}
    {
        package HeadModified;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'ForceCharset', {charset => 'Shift_JIS'}
            ]);
            
            $self->routes->any('/index')->to(cb => sub{
                $_[0]->render(text => '日本語');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('EnableIfFalse');
    $t->get_ok('/index')
        ->status_is(200)
        ->header_is('Content-length', 8)
        ->content_is('original');
}
    {
        package EnableIfFalse;
        use strict;
        use warnings;
        use base 'Mojolicious';
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'TestFilter', sub {0}
            ]);
            
            $self->routes->any('/index')->to(cb => sub{
                $_[0]->render(text => 'original');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    my $t = Test::Mojo->new('EnableIfTrue');
    $t->get_ok('/index')
        ->status_is(200)
        ->header_is('Content-length', 18)
        ->content_is('original[filtered]');
}
    {
        package EnableIfTrue;
        use strict;
        use warnings;
        use base 'Mojolicious';
        use Scalar::Util;
        use Test::More;
        
        sub startup {
            my $self = shift;
            
            $self->plugin('plack_middleware', [
                'TestFilter', sub {
                    ok($_[0]->isa('Mojolicious::Controller'), 'cb gets controller'); 1
                }, {
                    'arg1' => 'a',
                }
            ]);
            
            $self->routes->any('/index')->to(cb => sub{
                $_[0]->render(text => 'original');
            });
        }
    }

{
    $ENV{MOJO_MODE} = 'production';
    
    my $t = Test::Mojo->new('AppRejected');
    $t->get_ok('/index')
        ->status_is(401)
        ->header_is('Content-length', 22)
        ->content_is('Authorization required');
    
    my $t2 = Test::Mojo->new('AppRejected');
    $t2->get_ok('/index', {Authorization => "Basic dXNlcjpwYXNz"})
        ->status_is(200)
        ->header_is('Content-length', 8)
        ->content_is('original');
}
    {
        package AppRejected;
        use strict;
        use warnings;
        use base 'Mojolicious';
        use Scalar::Util;
        use Test::More;
        
        sub startup {
            my $self = shift;
            
            $self->plugin(plack_middleware => ["Auth::Basic", {authenticator => sub {1}}]);
            
            $self->routes->any('/index')->to(cb => sub{
                $_[0]->render(text => 'original');
            });
        }
    }

package Plack::Middleware::TestFilter;
use strict;
use warnings;
use base qw( Plack::Middleware );

sub call {
    
    my $self = shift;
    my $res = $self->app->(@_);
    $self->response_cb($res, sub {
        return sub {
            if (my $chunk = shift) {
                return $chunk. '[filtered]';
            }
        };
        $res;
    });
}

package Plack::Middleware::TestFilter2;
use strict;
use warnings;
use base qw( Plack::Middleware );

sub call {
    
    my $self = shift;
    my $res = $self->app->(@_);
    $self->response_cb($res, sub {
        return sub {
            if (my $chunk = shift) {
                return $chunk. '[filtered2]';
            }
        };
        $res;
    });
}

package Plack::Middleware::TestFilter3;
use strict;
use warnings;
use base qw( Plack::Middleware );

sub call {
    
    my $self = shift;
    my $res = $self->app->(@_);
    $self->response_cb($res, sub {
        return sub {
            if (my $chunk = shift) {
                return $chunk. "[$self->{tag}]";
            }
        };
        $res;
    });
}

package Plack::Middleware::TestFilter4;
use strict;
use warnings;
use base qw( Plack::Middleware );

sub call {
    
    my ($self, $env) = @_;
    $env->{PATH_INFO} .= '.html';
    my $res = $self->app->($env);
    return $res;
}

package Plack::Middleware::GrowLargeFilter;
use strict;
use warnings;
use base qw( Plack::Middleware );

sub call {
    
    my $self = shift;
    my $res = $self->app->(@_);
    $self->response_cb($res, sub {
        return sub {
            if (my $chunk = shift) {
                return $chunk. ("1234567890" x 10000);
            }
        };
        $res;
    });
}

package Plack::Middleware::ForceCharset;
use strict;
use warnings;
use 5.008_001;
use parent qw(Plack::Middleware);
use Plack::Util;
use Plack::Util::Accessor qw(charset);
use Encode;

our $VERSION = '0.02';

sub call {
    my ($self, $env) = @_;
    $self->response_cb($self->app->($env), sub {
        my $res = shift;
        my $h = Plack::Util::headers($res->[1]);
        my $charset_from = 'UTF-8';
        my $charset_to = $self->charset;
        my $ct = $h->get('Content-Type');
        if ($ct =~ s{;?\s*charset=([^;\$]+)}{}) {
            $charset_from = $1;
        }
        if ($ct =~ qr{^text/(html|plain)}) {
            $h->set('Content-Type', $ct. ';charset='. $charset_to);
        }
        my $fixed_body = [];
        Plack::Util::foreach($res->[2], sub {
            Encode::from_to($_[0], $charset_from, $charset_to);
            push @$fixed_body, $_[0];
        });
        $res->[2] = $fixed_body;
        $h->set('Content-Length', length $fixed_body);
        return $res;
    });
}

package Plack::Middleware::InvokeAppTwice;
use strict;
use warnings;
use base qw( Plack::Middleware );

sub call {
    
    my ($self, $env) = @_;
    my $res = $self->app->($env);
    if ($res->[0] == 404) {
        local $env->{PATH_INFO} = 'index2';
        $res = $self->app->($env);
    }
    return $res;
}

1;

__END__
