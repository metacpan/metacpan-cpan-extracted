package Mojolicious::Plugin::PlackMiddleware;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
use Plack::Util;
use Mojo::Message::Request;
use Mojo::Message::Response;
our $VERSION = '0.38';
use Scalar::Util 'weaken';
    
    ### ---
    ### register
    ### ---
    sub register {
        my ($self, $app, $mws) = @_;
        
        my $plack_app = sub {
            my $env = shift;
            my $c = $env->{'mojo.c'};
            my $tx = $c->tx;
            
            $tx->req(psgi_env_to_mojo_req($env));
            
            if ($env->{'mojo.routed'}) {
                my $stash = $c->stash;
                for my $key (grep {$_ =~ qr{^mojo\.}} keys %{$stash}) {
                    delete $stash->{$key};
                }
                delete $stash->{'status'};
                my $sever = $tx->res->headers->header('server');
                $tx->res(Mojo::Message::Response->new);
                $tx->res->headers->header('server', $sever);
                $c->match(Mojolicious::Routes::Match->new->root($c->app->routes));
                $env->{'mojo.inside_app'}->();
            } else {
                $env->{'mojo.inside_app'}->();
                $env->{'mojo.routed'} = 1;
            }
            
            return mojo_res_to_psgi_res($tx->res);
        };
            
        my @mws = reverse @$mws;
        while (scalar @mws) {
            my $args = (ref $mws[0] eq 'HASH') ? shift @mws : undef;
            my $cond = (ref $mws[0] eq 'CODE') ? shift @mws : undef;
            my $e = _load_class(shift @mws, 'Plack::Middleware');
            $plack_app = Mojolicious::Plugin::PlackMiddleware::_Cond->wrap(
                $plack_app,
                condition => $cond,
                builder => sub {$e->wrap($_[0], %$args)},
            );
        }
        
        $app->hook('around_dispatch' => sub {
            my ($next, $c) = @_;
            
            return $next->() if ($c->tx->req->error);
            
            my $plack_env = mojo_req_to_psgi_env($c->req);
            $plack_env->{'mojo.c'} = $c;
            $plack_env->{'mojo.inside_app'} = $next;
            $plack_env->{'psgi.errors'} =
                Mojolicious::Plugin::PlackMiddleware::_EH->new(sub {
                    $c->app->log->debug(shift);
                });
            
            $c->tx->res(psgi_res_to_mojo_res($plack_app->($plack_env)));
            $c->rendered if (! $plack_env->{'mojo.routed'});
        });
    }
    
    ### ---
    ### chunk size
    ### ---
    use constant CHUNK_SIZE => $ENV{MOJO_CHUNK_SIZE} || 131072;
    
    ### ---
    ### convert psgi env to mojo req
    ### ---
    sub psgi_env_to_mojo_req {
        
        my $env = shift;
        my $req = Mojo::Message::Request->new->parse($env);
        
        $req->reverse_proxy($env->{MOJO_REVERSE_PROXY});
        
        # Request body
        my $len = $env->{CONTENT_LENGTH};
        while (!$req->is_finished) {
            my $chunk = ($len && $len < CHUNK_SIZE) ? $len : CHUNK_SIZE;
            my $read = $env->{'psgi.input'}->read(my $buffer, $chunk, 0);
            last unless $read;
            $req->parse($buffer);
            $len -= $read;
            last if $len <= 0;
        }
        
        return $req;
    }
    
    ### ---
    ### convert mojo tx to psgi env
    ### ---
    sub mojo_req_to_psgi_env {
        
        my $mojo_req = shift;
        my $url = $mojo_req->url;
        my $base = $url->base;
        my $body =
        Mojolicious::Plugin::PlackMiddleware::_PSGIInput->new($mojo_req->build_body);
        
        my %headers_org = %{$mojo_req->headers->to_hash};
        my %headers;
        for my $key (keys %headers_org) {
            
            my $value = $headers_org{$key};
            $key =~ s{-}{_}g;
            $key = uc $key;
            $key = "HTTP_$key" if ($key !~ /^(?:CONTENT_LENGTH|CONTENT_TYPE)$/);
            $headers{$key} = $value;
        }
        
        return {
            %ENV,
            %headers,
            'SERVER_PROTOCOL'   => $base->protocol. '/'. $mojo_req->version,
            'SERVER_NAME'       => $base->host,
            'SERVER_PORT'       => $base->port,
            'REQUEST_METHOD'    => $mojo_req->method,
            'SCRIPT_NAME'       => '',
            'PATH_INFO'         => $url->path->to_string,
            'REQUEST_URI'       => $url->to_string,
            'QUERY_STRING'      => $url->query->to_string,
            'psgi.url_scheme'   => $base->scheme,
            'psgi.version'      => [1,1],
            'psgi.errors'       => *STDERR,
            'psgi.input'        => $body,
            'psgi.multithread'  => Plack::Util::FALSE,
            'psgi.multiprocess' => Plack::Util::TRUE,
            'psgi.run_once'     => Plack::Util::FALSE,
            'psgi.streaming'    => Plack::Util::TRUE,
            'psgi.nonblocking'  => Plack::Util::FALSE,
        };
    }
    
    ### ---
    ### convert psgi res to mojo res
    ### ---
    sub psgi_res_to_mojo_res {
        my $psgi_res = shift;
        my $mojo_res = Mojo::Message::Response->new;
        $mojo_res->code($psgi_res->[0]);
        my $headers = $mojo_res->headers;
        while (scalar @{$psgi_res->[1]}) {
            $headers->add(shift @{$psgi_res->[1]} => shift @{$psgi_res->[1]});
        }
        
        $headers->remove('Content-Length'); # should be set by mojolicious later
        
        my $asset = $mojo_res->content->asset;
        Plack::Util::foreach($psgi_res->[2], sub {$asset->add_chunk($_[0])});
        weaken($psgi_res);
        return $mojo_res;
    }
    
    ### ---
    ### convert mojo res to psgi res
    ### ---
    sub mojo_res_to_psgi_res {
        my $mojo_res = shift;
        my $status = $mojo_res->code;
        my $headers = $mojo_res->content->headers;
        my @headers;
        push @headers, $_ => $headers->header($_) for (@{$headers->names});
        my @body;
        my $offset = 0;
        
        # don't know why but this block makes long polling tests to pass
        if ($mojo_res->content->is_dynamic && $mojo_res->content->{delay}) {
            $mojo_res->get_body_chunk(0);
        }
        
        while (length(my $chunk = $mojo_res->get_body_chunk($offset))) {
            push(@body, $chunk);
            $offset += length $chunk;
        }
        return [$status, \@headers, \@body];
    }
    
    ### ---
    ### load mw class
    ### ---
    sub _load_class {
        my($class, $prefix) = @_;
        
        if ($prefix) {
            unless ($class =~ s/^\+// || $class =~ /^$prefix/) {
                $class = "$prefix\::$class";
            }
        }
        if ($class->can('call')) {
            return $class;
        }
        my $file = $class;
        $file =~ s!::!/!g;
        require "$file.pm"; ## no critic
    
        return $class;
    }


### ---
### Error Handler
### ---
package Mojolicious::Plugin::PlackMiddleware::_EH;
use Mojo::Base -base;
    
    __PACKAGE__->attr('handler');
    
    sub new {
        my ($class, $handler) = @_;
        my $self = $class->SUPER::new;
        $self->handler($handler);
    }
    
    sub print {
        my ($self, $error) = @_;
        $self->handler->($error);
    }

### ---
### Port of Plack::Middleware::Conditional with mojolicious controller
### ---
package Mojolicious::Plugin::PlackMiddleware::_Cond;
use strict;
use warnings;
use parent qw(Plack::Middleware::Conditional);
    
    sub call {
        my($self, $env) = @_;
        my $cond = $self->condition;
        if (! $cond || $cond->($env->{'mojo.c'}, $env)) {
            return $self->middleware->($env);
        } else {
            return $self->app->($env);
        }
    }
    
### ---
### PSGI Input handler
### ---
package Mojolicious::Plugin::PlackMiddleware::_PSGIInput;
use strict;
use warnings;
    
    sub new {
        my ($class, $content) = @_;
        return bless [$content, 0, length($content)], $class;
    }
    
    sub read {
        my $self = shift;
        my $offset = ($_[2] || $self->[1]);
        if ($offset <= $self->[2]) {
            if ($_[0] = substr($self->[0], $offset, $_[1])) {
                $self->[1] = $offset + length($_[0]);
                return 1;
            }
        }
    }

1;

__END__

=head1 NAME

Mojolicious::Plugin::PlackMiddleware - Plack::Middleware inside Mojolicious

=head1 SYNOPSIS

    # Mojolicious
    
    sub startup {
        my $self = shift;
        
        $self->plugin(plack_middleware => [
            'MyMiddleware1', 
            'MyMiddleware2', {arg1 => 'some_vale'},
            'MyMiddleware3', $condition_code_ref, 
            'MyMiddleware4', $condition_code_ref, {arg1 => 'some_value'}
        ]);
    }
    
    # Mojolicious::Lite
    
    plugin plack_middleware => [
        'MyMiddleware1', 
        'MyMiddleware2', {arg1 => 'some_vale'},
        'MyMiddleware3', $condition_code_ref, 
        'MyMiddleware4', $condition_code_ref, {arg1 => 'some_value'}
    ];
    
    package Plack::Middleware::MyMiddleware1;
    use strict;
    use warnings;
    use base qw( Plack::Middleware );
    
    sub call {
        my($self, $env) = @_;
        
        # pre-processing $env
        
        my $res = $self->app->($env);
        
        # post-processing $res
        
        return $res;
    }
  
=head1 DESCRIPTION

Mojolicious::Plugin::PlackMiddleware allows you to enable Plack::Middleware
inside Mojolicious using around_dispatch hook so that the portability of your
app covers pre/post process too.

It also aimed at those who used to Mojolicious bundle servers.
Note that if you can run your application on a plack server, there is proper
ways to use middlewares. See L<http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#Plack-middleware>.

=head2 OPTIONS

This plugin takes an argument in Array reference which contains some
middlewares. Each middleware can be followed by callback function for
conditional activation, and attributes for middleware.

    my $condition = sub {
        my $c   = shift; # Mojolicious controller
        my $env = shift; # PSGI env
        if (...) {
            return 1; # causes the middleware hooked
        }
    };
    plugin plack_middleware => [
        Plack::Middleware::MyMiddleware, $condition, {arg1 => 'some_value'},
    ];

=head1 METHODS

=head2 register

$plugin->register;

Register plugin hooks in L<Mojolicious> application.

=head2 psgi_env_to_mojo_req

This is a utility method. This is for internal use.

    my $mojo_req = psgi_env_to_mojo_req($psgi_env)

=head2 mojo_req_to_psgi_env

This is a utility method. This is for internal use.

    my $plack_env = mojo_req_to_psgi_env($mojo_req)

=head2 psgi_res_to_mojo_res

This is a utility method. This is for internal use.

    my $mojo_res = psgi_res_to_mojo_res($psgi_res)

=head2 mojo_res_to_psgi_res

This is a utility method. This is for internal use.

    my $psgi_res = mojo_res_to_psgi_res($mojo_res)

=head1 Example

Plack::Middleware::Auth::Basic

    $self->plugin(plack_middleware => [
        'Auth::Basic' => sub {shift->req->url =~ qr{^/?path1/}}, {
            authenticator => sub {
                my ($user, $pass) = @_;
                return $user eq 'user1' && $pass eq 'pass';
            }
        },
        'Auth::Basic' => sub {shift->req->url =~ qr{^/?path2/}}, {
            authenticator => sub {
                my ($user, $pass) = @_;
                return $user eq 'user2' && $pass eq 'pass2';
            }
        },
    ]);

Plack::Middleware::ErrorDocument

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

Plack::Middleware::JSONP

    $self->plugin('plack_middleware', [
        JSONP => {callback_key => 'json.p'},
    ]);

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
