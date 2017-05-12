package Orochi::Declare;
use strict;
use Orochi;
use Carp ();
use Sub::Exporter -setup => {
    exports => [ qw( bind_value container inject_constructor inject_literal ) ],
    groups  => [ default => [':all'] ]
};

sub unimport {
    my $package = caller(0);
    foreach my $name qw( bin_value container inject_constructor inject_literal ) {
        no strict 'refs';

        if ( defined &{ $package . '::' . $name } ) {
            my $sub = \&{ $package . '::' . $name };
            next unless \&{$name} == $sub;

            delete ${ $package . '::' }{$name};
        }
    }
}

our $__CONTAINER;
sub container(&) {
    my $c = Orochi->new();
    {
        local $__CONTAINER = $c;
        $_[0]->();
    }
    return $c;
}

sub __CONTAINER__ {
    my $method = (caller(1))[3];
    return $__CONTAINER || 
        Carp::confess("Attempting to run $method from outside a container");
}

sub inject_constructor ($@) {
    return __CONTAINER__->inject_constructor(@_);
}

sub inject_literal ($$) {
    return __CONTAINER__->inject_literal(@_);
}

sub bind_value ($) {
    return __CONTAINER__->bind_value(@_);
}

1;

__END__

=head1 NAME

Orochi::Declare - Declarative Style Orochi DI

=head1 SYNOPSIS

    use Orochi::Declare;

    my $c = container {
        inject_constructor '/myapp' => (
            class => 'MyApp',
            args  => {
                foo => bind_value '/myapp/foo',
            }
        );
        inject_constructor '/myapp/foo' => (
            class => 'MyApp::Foo',
            args  => {
                bar => bind_value '/myapp/foo/bar'
            }
        );
        inject_literal '/myapp/foo/bar' => 1;
    }

    my $myapp = $c->get('/myapp');

=cut