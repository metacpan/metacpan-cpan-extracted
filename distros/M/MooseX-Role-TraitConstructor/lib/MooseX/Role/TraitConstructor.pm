#!/usr/bin/perl

package MooseX::Role::TraitConstructor;
use Moose::Role;

use List::Util ();

our $VERSION = "0.01";

use constant constructor_trait_param => "traits";

sub new_with_traits {
    my ( $class, @opts ) = @_;

    my %params;

    if (scalar @opts == 1) {
        if (defined $opts[0]) {
            (ref($opts[0]) eq 'HASH')
                || confess "Single parameters to new() must be a HASH ref";
            %params = %{$opts[0]};
        }
    }
    else {
        %params = @opts;
    }

    $class->interpolate_class_from_params(\%params)->new(%params);
}

sub interpolate_class_from_params {
    my ($class, $params) = @_;

    $class = ref($class) || $class;

    my @traits;

    if (my $traits = delete $params->{$class->constructor_trait_param($params)}) {
        if ( @traits = $class->process_constructor_traits($params, @$traits) ) {
            my $anon_class = Moose::Meta::Class->create_anon_class(
                superclasses => [ $class ],
                roles        => [ @traits ],
                cache        => 1,
            );

            $class = $anon_class->name;
        }
    }

    return ( wantarray ? ( $class, @traits ) : $class );
}

sub process_constructor_traits {
    my ( $class, $params, @traits ) = @_; 

    $class->filter_constructor_traits( $params, $class->resolve_constructor_traits( $params, @traits ) );

}

sub resolve_constructor_traits {
    my ( $class, $params, @traits ) = @_; 

    my $root = $class->guess_original_class_name($params);

    map { $class->resolve_constructor_trait($params, $root, $_) } @traits;
}

sub guess_original_class_name {
    my ( $class, $params ) = @_;

    my $meta = $class->meta;

    if ( $meta->is_anon_class ) {
        if ( my $root = List::Util::first(sub { not $_->meta->is_anon_class }, $meta->linearized_isa ) ) {
            return $root;
        }
    }

    return $class;
}

sub resolve_constructor_trait {
    my ( $class, $params, $possible_root, $trait ) = @_;

    if ( ref $trait ) {
        return $trait->anme;
    } else {
        my $processed_trait;

        {
            local $@;
            if ( $processed_trait = $class->process_trait_name($trait, $params, $possible_root) ) {
                if ( eval { Class::MOP::load_class($processed_trait); 1 } ) {
                    return $processed_trait;
                }
            }

            if ( eval { Class::MOP::load_class($trait); 1 } ) {
                return $trait;
            }
        }

        require Carp;
        Carp::croak("Couldn't load $trait" . ( $processed_trait ? " or $processed_trait" : "" ) . " to mix in with $class" . ( $class->meta->is_anon_class ? " ($possible_root)" : "" ));
    }
}

sub process_trait_name {
    my ( $class, $trait, $params, $possible_root) = @_;

    return join "::", $possible_root, $trait;
}

sub filter_constructor_traits {
    my ( $class, $params, @traits ) = @_;

    return grep { not $class->does($_) } @traits;
}

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::Role::TraitConstructor - A wrapper for C<new> that can accept a
C<traits> parameter.

=head1 SYNOPSIS

    package Foo;
    use Moose;

	with qw(MooseX::Role::TraitConstructor);


    package Foo::Bah;

    sub bah_method { ... }



    my $foo = Foo->new( traits => [qw( Bah )] );

    $foo->bah_method;

=head1 DESCRIPTION

This role allows you to easily accept a C<traits> argument (or another name)
into your constructor, which will easily mix roles into an anonymous class
before construction, much like L<Moose::Meta::Attribute> does.

=head1 METHODS

=over 4

=item constructor_trait_param

Returns the string C<traits>.

Override to rename the parameter.

=item new_with_traits %params

=item new_with_traits $params

A L<Moose::Object/new> like parameter processor which will call C<new> on the
return value of C<interpolate_class_from_params>.

=item interpolate_class_from_params $params

This method will automatically create an anonymous class with the roles from
the C<traits> param mixed into it if one exists.

If not the normal class name will be returned.

Will remove the C<traits> parameter from C<$params>.

Also works as an instance method, but always returns a class name.

In list context also returns the actual list of roles mixed into the class.

=item process_constructor_traits $params, @traits

Calls C<filter_constructor_traits> on the result of C<resolve_constructor_traits>.

=item resolve_constructor_traits $params, @traits

Attempt to load the traits specified in C<@traits> usinc C<resolve_constructor_trait>

=item guess_original_class_name $params

=item resolve_constructor_trait $params, $possible_root, $trait

Attempts to get a processed name from C<process_trait_name>, and then tries to load that.

If C<process_trait_name> didn't return a true value or its return value could
not be loaded then C<$trait> will be tried.

If nothing could be loaded an error is thrown.

C<$possible_root> is the name of the first non anonymous class in the
C<linearized_isa>, usually C<$class>, but will DWIM in case C<$class> has
already been interpolated with traits from a named class.

=item process_trait_name $trait, $params, $possible_root

Returns C<< join "::", $possible_root, $trait >>.

You probably want to override this method.

=item filter_constructor_traits $params, $traits, 

Returns all the the roles that the invocant class doesn't already do (uses
C<does>).

=back

=head1 VERSION CONTROL

L<http://code2.0beta.co.uk/moose/svn/>. Ask on #moose for commit bits.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
