package Rose::HTMLx::Form::Related::DBIC::Metadata;
use strict;
use base qw( Rose::HTMLx::Form::Related::Metadata );
use Carp;
use Data::Dump qw( dump );
use Rose::Object::MakeMethods::Generic (
    'scalar --get_set_init' => [qw( schema_class )],

);
use MRO::Compat;
use mro 'c3';

our $VERSION = '0.24';

=head1 NAME

Rose::HTMLx::Form::Related::DBIC::Metadata - DBIC metadata driver

=head1 SYNOPSIS

 see Rose::HTMLx::Form::Related::Metadata

=head1 METHODS

Only overriden or new methods are described here.

=head2 discover_relationships

Implements DBIC relationship introspection.
As with DBIC->get_objects() and DBIC->get_objects_count(),
discover_relationships() will be a no-op of the 
DBIC_DEPLOY_IN_PROGRESS env var is true.

=cut

sub discover_relationships {
    my $self = shift;

    if ( $ENV{DBIC_DEPLOY_IN_PROGRESS} ) {
        return $self->relationships( [] );
    }

    # if running under Catalyst (e.g.) get controller info
    my $app = $self->form->app_class || $self->form->app;

    # get relationship objects from DBIC
    my %seen;
    my $class   = $self->schema_class->class( $self->object_class );
    my $moniker = $self->form->_get_moniker( $self->schema_class, $class );
    my $source  = $self->schema_class->source($moniker);

    #warn '=' x 50 . "\nclass $class moniker $moniker source $source";

    my @relinfos;

    for my $r ( $source->relationships ) {
        my $dbic_info = $class->relationship_info($r);
        my $relinfo   = $self->relinfo_class->new;

        #warn '-' x 50 . "\n$r : " . dump $dbic_info;

        my $type = $dbic_info->{attrs}->{accessor};

        # method and name may be reset below via $m2m
        my $method = $r;

        $relinfo->object_class($class);
        $relinfo->name($r);
        $relinfo->method($method);
        $relinfo->label(
            $self->labels->{$method} || join(
                ' ', map { ucfirst($_) }
                    split( m/_/, $method )
            )
        );

        # could be one2many or many2many
        if ( $type eq 'multi' ) {

            #warn "$r is multi";

            if ( exists $dbic_info->{m2m} ) {

                my $m2m = $dbic_info->{m2m};

                #warn dump $m2m;

                $relinfo->type('many to many');
                $relinfo->method( $m2m->{method_name} );
                $relinfo->name( $m2m->{method_name} );    # $r ??
                $relinfo->map_class( $m2m->{map_class} );
                $relinfo->map_from( $m2m->{map_from} );
                $relinfo->foreign_class( $m2m->{foreign_class} );
                $relinfo->map_to( $m2m->{map_to} );
                $relinfo->map_to_column( $m2m->{map_to_column} );
                $relinfo->map_from_column( $m2m->{map_from_column} );
                $relinfo->label(
                    $self->labels->{ $relinfo->method } || join( ' ',
                        map { ucfirst($_) }
                            split( m/_/, $relinfo->method ) )
                );

            }
            else {

                # one2many
                my @foreign = keys %{ $dbic_info->{cond} };
                $relinfo->cmap( {} );
                for my $foreign (@foreign) {
                    my $local = $dbic_info->{cond}->{$foreign};
                    $foreign =~ s/^foreign\.//;
                    $local   =~ s/^self\.//;
                    $relinfo->cmap->{$local} = $foreign;
                    $relinfo->type('one to many');
                    $relinfo->foreign_class( $dbic_info->{class} );
                }

            }

        }
        elsif ( ref( $dbic_info->{cond} ) eq 'HASH' ) {

            # 'single' et al treat like FK
            my @foreign = keys %{ $dbic_info->{cond} };
            $relinfo->cmap( {} );
            for my $foreign (@foreign) {
                my $local = $dbic_info->{cond}->{$foreign};
                $foreign =~ s/^foreign\.//;
                $local   =~ s/^self\.//;
                $relinfo->cmap->{$local} = $foreign;
                $relinfo->type('foreign key');
                $relinfo->foreign_class( $dbic_info->{class} );
            }
        }
        else {

            croak "unknown relationship type: " . dump $dbic_info;

        }

        if ($app) {

            $relinfo->app($app);

            # create URL and controller if available.
            my $prefix          = $class->schema_class_prefix;
            my $controller_name = $relinfo->foreign_class;
            if ( !$controller_name ) {
                croak "no foreign class in relinfo: " . dump $relinfo;
            }
            $controller_name =~ s/^${prefix}:://;
            my $controller_prefix = $self->controller_prefix;
            $relinfo->controller_class(
                join( '::',
                    grep { defined($_) }
                        ( $controller_prefix, $controller_name ) )
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

        push @relinfos, $relinfo;

    }

    $self->relationships( \@relinfos );
}

=head2 show_related_field_using

Overrides base method to understand DBIx::Class
objects.

=cut

sub show_related_field_using {
    my $self   = shift;
    my $fclass = shift or croak "foreign_object_class required";
    my $field  = shift or croak "field_name required";

    my $method = $self->next::method( $fclass, $field );
    return $method if $method;

    # find the first unique single-col column of type char/varchar
    for my $constraint ( $fclass->unique_constraint_names ) {

        $self->form->debug
            and warn "constraint name for $fclass: $constraint";
        my @u = $fclass->unique_constraint_columns($constraint);
        next if @u > 1;
        for my $column (@u) {

            my $info = $fclass->column_info($column);

            $self->form->debug
                and warn "column $column : " . dump $info;

            if ( defined $info->{data_type}
                and $info->{data_type} =~ m/char/ )
            {
                return $column;
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
