package Pulp::Route;

use warnings;
use strict;
use true;

sub import {
    my $routes = {};
    my $caller = caller;
    strict->import();
    warnings->import();
    true->import();
    {
        no strict 'refs';
        push @{"${caller}::ISA"}, 'Kelp';
        *{"${caller}::new"} = sub { return shift->SUPER::new(@_); };

        *{"${caller}::everything"} = sub { return "(.+)"; };
        *{"${caller}::get"} = sub {
            my ($name, $coderef) = @_;
            $routes->{$name} = {
                type    => 'get',
                coderef => $coderef,
            };
        };

        *{"${caller}::post"} = sub {
            my ($name, $coderef) = @_;
            $routes->{$name} = {
                type    => 'post',
                coderef => $coderef,
            };
        };

        *{"${caller}::any"} = sub {
            my ($name, $coderef) = @_;
            $routes->{$name} = {
                type    => 'any',
                coderef => $coderef,
            };
        };

        *{"${caller}::bridge"} = sub {
            my ($name, $coderef, $type) = @_;
            $type //= 'get';
            $routes->{$name} = {
               type     => $type,
               coderef  => $coderef,
               bridge   => 1,
            };
        };

        *{"${caller}::get_routes"} = sub {
            return $routes;
        };
    }
}

1;
__END__
