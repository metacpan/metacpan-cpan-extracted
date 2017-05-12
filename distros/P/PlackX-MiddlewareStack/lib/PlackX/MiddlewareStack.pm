package PlackX::MiddlewareStack;
use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.011';

use Tie::LLHash;

sub new {
    my $class       = shift;
    my %middlewares = ();
    tie( %middlewares, 'Tie::LLHash' );
    bless { middlewares => \%middlewares }, $class;
}

sub add {
    my ( $self, $mw_class, $args ) = @_;

    my $mw = $self->_to_middleware( $mw_class, $args );
    ( tied %{ $self->{middlewares} } )->last( $mw_class => $mw );
}

sub insert_after {
    my ( $self, $mw_class_to_add, $args, $target_mw_class ) = @_;

    my $mw = $self->_to_middleware( $mw_class_to_add, $args );
    ( tied %{ $self->{middlewares} } )
        ->insert( $mw_class_to_add => $mw, $target_mw_class );
}

sub insert_before {
    my ( $self, $mw_class_to_add, $args, $target_mw_class ) = @_;

    my $mw = $self->_to_middleware( $mw_class_to_add, $args );
    my $before_target
        = ( tied %{ $self->{middlewares} } )->key_before($target_mw_class);
    ( tied %{ $self->{middlewares} } )
        ->insert( $mw_class_to_add => $mw, $before_target );
}

sub to_app {
    my ( $self, $app ) = @_;

    for my $mw_class ( reverse keys %{ $self->{middlewares} } ) {
        my $mw = $self->{middlewares}->{$mw_class};
        $app = $mw->($app);
    }
    $app;
}

sub _to_middleware {
    my ( $self, $mw_class, $args ) = @_;

    eval "use $mw_class";
    die $@ if $@;

    my @args = ();
    while ( my ( $key, $value ) = each( %{ $args || {} } ) ) {
        push @args, $key;
        push @args, $value;
    }

    my $mw = sub { $mw_class->wrap( $_[0], @args ) };
    $mw;
}

sub middleware_classes {
    keys %{ shift->{middlewares} };
}

1;

__END__

=encoding utf-8

=head1 NAME

PlackX::MiddlewareStack - forms a complete PSGI application from various middlewares

=head1 SYNOPSIS

add a middleware:

    use PlackX::MiddlewareStack;
    my $builder = PlackX::MiddlewareStack->new;
    $builder->add( 'Plack::Middleware::XFramework', { framework => 'Dog' } );
    $builder->add('Plack::Middleware::Static');
    my $psgi_handler =  sub { [ 200, [], ['ok'] ];};
    my $handler = $builder->to_app($psgi_handler);

insert a middleware after middleware:

    use PlackX::MiddlewareStack;
    my $builder = PlackX::MiddlewareStack->new;
    $builder->add( 'Plack::Middleware::XFramework', { framework => 'Dog' } );
    $builder->add('Plack::Middleware::Static');
    $builder->insert_after(
        'Plack::Middleware::Lint' => {},
        'Plack::Middleware::XFramework'
    );
    my $psgi_handler =  sub { [ 200, [], ['ok'] ];};
    my $handler = $builder->to_app($psgi_handler);

insert a middleware before middleware:

    my $builder = PlackX::MiddlewareStack->new;
    $builder->add( 'Plack::Middleware::XFramework', { framework => 'Dog' } );
    $builder->add('Plack::Middleware::Static');
    $builder->insert_before(
        'Plack::Middleware::Lint' => {},
        'Plack::Middleware::XFramework'
    );
    my $psgi_handler =  sub { [ 200, [], ['ok'] ];};
    my $handler = $builder->to_app($psgi_handler);
 
=head1 DESCRIPTION

PlackX::MiddlewareStack combines various internal and external middlewares to form a 
complete Plack application.

=head1 SOURCE AVAILABILITY

This source is in Github:

  http://github.com/dann/p5-plackx-middlewarestack

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
