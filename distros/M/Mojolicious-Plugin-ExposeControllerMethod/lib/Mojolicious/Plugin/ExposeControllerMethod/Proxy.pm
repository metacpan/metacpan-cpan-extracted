package Mojolicious::Plugin::ExposeControllerMethod::Proxy;

use strict;
use warnings;

our $VERSION = '1.000001';

our $AUTOLOAD;

sub import  { return }
sub DESTROY { return }

## no critic (ClassHierarchies::ProhibitAutoloading)
sub AUTOLOAD {
    my $self = shift;
    my $c    = ${$self};

    my ($what) = $AUTOLOAD =~ /([^:]+)$/;

    my $controller_method_name = $c->can('controller_method_name');
    unless ($controller_method_name) {
        die 'Controller class '
            . ref($c)
            . ' does not allow calling methods from the template';
    }

    my $method_name = $controller_method_name->( $c, $what );
    unless ($method_name) {
        die "Invalid method '$what' called on contolling class";
    }

    # install a method in the proxy class so we don't have to do this lookup again
    {
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        *{$AUTOLOAD} = sub {
            my $that_self = shift;
            my $that_c    = ${$self};
            return $that_c->$method_name(@_);
        };
        ## use critic
    }

    return $c->$method_name(@_);
}

1;

=head1 NAME

Mojolicious::Plugin::ExposeControllerMethod::Proxy - helper class for Mojolicious::Plugin::ExposeControllerMethod

=head1 DESCRIPTION

The proxy class for Mojolicious::Plugin::ExposeControllerMethod.  No user
service parts here.

=head1 SEE ALSO

L<Mojolicious::Plugin::ExposeControllerMethod>


