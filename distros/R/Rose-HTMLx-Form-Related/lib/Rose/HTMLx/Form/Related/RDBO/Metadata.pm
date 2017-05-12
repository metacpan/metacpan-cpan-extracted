package Rose::HTMLx::Form::Related::RDBO::Metadata;
use strict;
use base qw( Rose::HTMLx::Form::Related::Metadata );
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';

our $VERSION = '0.24';

=head1 NAME

Rose::HTMLx::Form::Related::RDBO::Metadata - RDBO metadata driver

=head1 SYNOPSIS

 see Rose::HTMLx::Form::Related::Metadata

=head1 METHODS

Only overriden methods are described here.

=head2 discover_relationships

Implements RDBO relationship introspection.

=cut

sub discover_relationships {
    my $self = shift;

    my $debug = $self->form->debug;

    # if running under Catalyst (e.g.) get controller info
    my $app = $self->form->app_class || $self->form->app;

    # get relationship objects from RDBO
    my %seen;
    my @fks = $self->object_class->meta->foreign_keys;
    my @rel = $self->object_class->meta->relationships;
    my @rels;
    for my $r ( @fks, @rel ) {

        # screen out duplicates since FKs masquerade as Rels
        next if $seen{ $r->name }++;
        push( @rels, $r );
    }

    my @relinfos;

    # create our RelInfo objects
    for my $rdbo_rel (@rels) {

        my $relinfo = $self->relinfo_class->new;
        my $name    = $rdbo_rel->name;
        my $type    = $rdbo_rel->type;
        $relinfo->object_class( $self->object_class );
        $relinfo->name($name);
        $relinfo->method($name);
        $relinfo->type($type);
        $relinfo->label(
            $self->labels->{$name} || join(
                ' ', map { ucfirst($_) }
                    split( m/_/, $name )
            )
        );

        $debug and carp dump $relinfo;

        if ( $type eq 'many to many' ) {
            my $map_to    = $rdbo_rel->map_to;
            my $map_class = $rdbo_rel->map_class;
            $debug and carp "map_to = $map_to";
            $debug and carp "map_class = $map_class";
            $debug and carp dump $map_class->meta;
            my $foreign_rel = $map_class->meta->relationship($map_to);
            my $local_rel
                = $map_class->meta->relationship( $rdbo_rel->map_from );
            my @forcolmap = %{ $foreign_rel->column_map };
            $debug and carp dump \@forcolmap;
            my @loccolmap = %{ $local_rel->column_map };
            $relinfo->map_class($map_class);
            $relinfo->foreign_class( $foreign_rel->class );
            $relinfo->map_to($map_to);
            $relinfo->map_to_column( $forcolmap[0] );
            $relinfo->map_from_column( $loccolmap[0] );
            $relinfo->map_from( $rdbo_rel->map_from );
        }
        else {
            $relinfo->foreign_class( $rdbo_rel->class );
            $relinfo->cmap( { $rdbo_rel->column_map } );
        }

        if ($app) {

            $relinfo->app($app);

            # create URL and controller if available.
            my $prefix          = $self->object_class->schema_class_prefix;
            my $controller_name = $relinfo->foreign_class;
            if ( !$controller_name ) {
                croak "no foreign class in relinfo: " . dump $relinfo;
            }
            $controller_name =~ s/^${prefix}:://;
            $relinfo->controller_class(
                join( '::',
                    grep { defined($_) }
                        ( $self->controller_prefix, $controller_name ) )
            );
            if ( $relinfo->map_class ) {
                my $map_class_prefix
                    = $relinfo->map_class->schema_class_prefix;
                my $controller_name = $relinfo->map_class;
                $controller_name =~ s/^${map_class_prefix}:://;
                $relinfo->map_class_controller_class(
                    join( '::',
                        grep { defined($_) }
                            ( $self->controller_prefix, $controller_name ) )
                );
            }

            # only want a controller instance if $app is fully
            # initialized (not a class name)
            if ( ref $app ) {
                $relinfo->controller(
                    $app->controller( $relinfo->controller_class ) );
            }

        }

        push( @relinfos, $relinfo );

    }

    $self->relationships( \@relinfos );

}

=head2 show_related_field_using

Overrides base method to understand Rose::DB::Object::Metadata
objects.

=cut

sub show_related_field_using {
    my $self   = shift;
    my $fclass = shift or croak "foreign_object_class required";
    my $field  = shift or croak "field_name required";

    my $method = $self->next::method( $fclass, $field );
    return $method if $method;

    # find the first single-column unique char/varchar method name
    my @ukeys = $fclass->meta->unique_keys_column_names;
    if (@ukeys) {
        for my $k (@ukeys) {
            if ( scalar(@$k) == 1
                && $fclass->meta->column( $k->[0] )->type =~ m/char/ )
            {
                return $k->[0];    # TODO column alias ??
            }
        }
    }
    return undef;
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
