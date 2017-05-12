package Rose::HTMLx::Form::Related::DBIC;
use strict;
use warnings;
use base qw( Rose::HTMLx::Form::Related );
use Rose::HTMLx::Form::Related::DBIC::Metadata;
use Carp;
use Data::Dump qw( dump );

our $VERSION = '0.24';

=head1 NAME

Rose::HTMLx::Form::Related::DBIC - DBIC with RHTMLO

=head1 SYNOPSIS

 package MyDBIC::Class::Form;
 use strict;
 use base qw( Rose::HTMLx::Form::Related::RDBO );
 
 sub init_object_class { 'MyDBIC::Class' }
 
 1;

=head1 DESCRIPTION

Use Rose::HTML::Objects forms with DBIx::Class.

B<NOTE:> This class requires that your DBIC schema load
the DBIx::Class::RDBOHelpers component, available from CPAN.
See examples in the t/ test directory with this distribution.

=head1 METHODS

=cut

=head2 init_metadata_class

Returns 'Rose::HTMLx::Form::Related::RDBO::Metadata'.

=cut

sub init_metadata_class {
    return 'Rose::HTMLx::Form::Related::DBIC::Metadata';
}

=head2 get_objects( object_class => I<class> )

Overrides base method to use schema_class()
to fetch objects of I<class>.

If you are using the deploy() feature of DBIC you may
encounter a race condition where the schema has not yet
fully populated. In that case, you may want to set the
C<DBIC_DEPLOY_IN_PROGRESS> environment variable prior
to instantiating this Form. If that variable is set to a true
value, get_objects() and get_objects_count() will both
return undef, which should abort the interrelate_fields()
method (which is what you want).

=cut

sub _get_moniker {
    my ( $self, $schema, $class ) = @_;
    for my $moniker ( $schema->sources ) {
        if ( $schema->class($moniker)->isa($class) ) {
            return $moniker;
        }
    }
    croak "could not find moniker for $class in $schema";
}

sub get_objects {
    return undef if $ENV{DBIC_DEPLOY_IN_PROGRESS};
    my $self    = shift;
    my $class   = pop;
    my $schema  = $self->metadata->schema_class;
    my $moniker = $self->_get_moniker( $schema, $class );
    return [
        $schema->connect( $schema->init_connect_info )->resultset($moniker)
            ->all() ];
}

=head2 get_objects_count( object_class => I<class> )

Overrides base method to use schema_class()
to fetch object count for I<class>.

See the C<DBIC_DEPLOY_IN_PROGRESS> environment variable above.

=cut

sub get_objects_count {
    return undef if $ENV{DBIC_DEPLOY_IN_PROGRESS};
    my $self    = shift;
    my $class   = pop;
    my $schema  = $self->metadata->schema_class;
    my $moniker = $self->_get_moniker( $schema, $class );
    return $schema->connect( $schema->init_connect_info )->resultset($moniker)
        ->count();
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
