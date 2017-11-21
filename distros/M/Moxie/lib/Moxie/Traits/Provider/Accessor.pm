package Moxie::Traits::Provider::Accessor;
# ABSTRACT: built in traits

use v5.22;
use warnings;
use experimental qw[
    signatures
    postderef
];

use Method::Traits ':for_providers';

use Carp      ();
use MOP::Util ();

our $VERSION   = '0.07';
our $AUTHORITY = 'cpan:STEVAN';

sub ro ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        if ( $method_name =~ /^get_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build `ro` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        Carp::confess("Cannot assign to `$slot_name`, it is a readonly") if scalar @_ != 1;
        $_[0]->{ $slot_name };
    });
}

sub rw ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        $slot_name = $method_name;
    }

    Carp::confess('Unable to build `rw` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('Moxie::Object::Immutable');

    Carp::confess('Unable to build `rw` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        $_[0]->{ $slot_name } = $_[1] if scalar( @_ ) > 1;
        $_[0]->{ $slot_name };
    });
}

sub wo ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        if ( $method_name =~ /^set_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build `wo` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('Moxie::Object::Immutable');

    Carp::confess('Unable to build `wo` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        Carp::confess("You must supply a value to write to `$slot_name`") if scalar(@_) < 1;
        $_[0]->{ $slot_name } = $_[1];
    });
}

sub predicate ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        if ( $method_name =~ /^has_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build predicate for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub { defined $_[0]->{ $slot_name } } );
}

sub clearer ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        if ( $method_name =~ /^clear_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build `clearer` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('Moxie::Object::Immutable');

    Carp::confess('Unable to build `clearer` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub { undef $_[0]->{ $slot_name } } );
}


1;

__END__

=pod

=head1 NAME

Moxie::Traits::Provider::Accessor - built in traits

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This is a L<Method::Traits> provider module which L<Moxie> enables by
default. These are documented in the L<METHOD TRAITS> section of the
L<Moxie> documentation.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
