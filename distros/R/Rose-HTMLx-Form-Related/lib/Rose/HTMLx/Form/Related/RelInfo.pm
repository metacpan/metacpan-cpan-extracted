package Rose::HTMLx::Form::Related::RelInfo;
use strict;
use warnings;
use base qw( Rose::Object );
use Rose::Object::MakeMethods::Generic (
    'scalar --get_set' => [
        qw( name type method label
            object_class foreign_class foreign_column
            map_from map_to map_class map_to_column map_from_column
            cmap controller controller_class app
            map_class_controller_class
            )
    ],
);
use Carp;
use Scalar::Util;

our $VERSION = '0.24';

=head1 NAME

Rose::HTMLx::Form::Related::RelInfo - relationship summary

=head1 DESCRIPTION

Objects of this class are get/set from the various relationship
methods in Metadata. See Rose::HTMLx::Form::Related::Metadata
init_relationships().

=head1 METHODS

These are all get/set methods.

=head2 app

=head2 name

=head2 type

=head2 method

=head2 label

=head2 object_class

=head2 foreign_class

=head2 foreign_column

=head2 map_from

=head2 map_to

=head2 map_class

=head2 map_to_column

=head2 map_from_column

=head2 map_class_controller_class

=head2 cmap

=head2 controller

=head2 controller_class

=cut

=head2 get_controller

Returns controller() or fetches and caches a controller instance based
on app().

=cut

sub get_controller {
    my $self = shift;
    return $self->controller if defined $self->controller;
    my $c = $self->app->controller( $self->controller_class );
    $self->controller($c);
    return $c;
}

=head2 foreign_column_for( I<field_name> )

Returns the name of the foreign column related to I<field_name>.
Shortcut for looking up items in cmap().

=cut

sub foreign_column_for {
    my $self = shift;
    my $name = shift;
    if ( ref( $self->foreign_column ) ) {
        return $self->foreign_column->{$name};
    }
    else {
        return $self->foreign_column;
    }
}

=head2 as_hash

Returns all non-blessed values in a single hashref. Suitable for debugging.

=cut

sub as_hash {
    my $self = shift;
    my %hash;
    for my $key ( keys %$self ) {
        my $value = $self->$key;
        if ( !Scalar::Util::blessed($value) ) {
            $hash{$key} = $value;
        }
    }
    return \%hash;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-htmlx-form-related at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-HTMLx-Form-Related>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::HTMLx::Form::Related

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-HTMLx-Form-Related>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-HTMLx-Form-Related>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-HTMLx-Form-Related>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-HTMLx-Form-Related>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
