package Puncheur::Dispatcher::Lite;
use strict;
use warnings;
use Router::Boom::Method;

sub import {
    my $class = shift;
    my $caller = caller(0);


    my $router = Router::Boom::Method->new;
    my $base;

    no strict 'refs';
    *{"${caller}::base"} = sub { $base = $_[0] };

    # copied from Amon2::Web::Dispatcher::RouterBoom
    # functions
    #
    # get( '/path', 'Controller#action')
    # post('/path', 'Controller#action')
    # delete_('/path', 'Controller#action')
    # any( '/path', 'Controller#action')
    # get( '/path', sub { })
    # post('/path', sub { })
    # delete_('/path', sub { })
    # any( '/path', sub { })
    for my $method (qw(get post delete_ any)) {
        *{"${caller}::${method}"} = sub {
            use strict 'refs';
            my ($path, $dest) = @_;

            my %dest;
            if (ref $dest eq 'CODE') {
                $dest{code} = $dest;
            }
            else {
                my ($controller, $method) = split('#', $dest);
                $dest{class}      = $base ? "${base}::${controller}" : $controller;
                $dest{method}     = $method if defined $method;
            }

            my $http_method;
            if ($method eq 'get') {
                $http_method = ['GET','HEAD'];
            } elsif ($method eq 'post') {
                $http_method = 'POST';
            } elsif ($method eq 'delete_') {
                $http_method = 'DELETE';
            }

            $router->add($http_method, $path, \%dest);
        };
    }

    # class methods
    *{"${caller}::router"} = sub { $router };

    *{"${caller}::dispatch"} = sub {
        my ($class, $c) = @_;
        $c = $class unless $c;

        my $env = $c->request->env;
        if (my ($dest, $captured, $method_not_allowed) = $class->router->match($env->{REQUEST_METHOD}, $env->{PATH_INFO})) {
            if ($method_not_allowed) {
                return $c->res_405;
            }

            my $res = eval {
                if ($dest->{code}) {
                    return $dest->{code}->($c, $captured);
                } else {
                    my $method = $dest->{method};
                    $c->{args} = $captured;
                    return $dest->{class}->$method($c, $captured);
                }
            };
            if ($@) {
                if ($class->can('handle_exception')) {
                    return $class->handle_exception($c, $@);
                }
                else {
                    print STDERR "$env->{REQUEST_METHOD} $env->{PATH_INFO} [$env->{HTTP_USER_AGENT}]: $@";
                    return $c->res_500;
                }
            }
            return $res;
        }
        else {
            return $c->res_404;
        }
    };
}

1;
