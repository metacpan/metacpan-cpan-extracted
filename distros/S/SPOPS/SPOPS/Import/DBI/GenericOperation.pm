package SPOPS::Import::DBI::GenericOperation;

# $Id: GenericOperation.pm,v 1.2 2004/06/02 00:33:20 lachoy Exp $

use strict;
use base qw( SPOPS::Import );
use SPOPS::Exception qw( spops_error );
use SPOPS::SQLInterface;

$SPOPS::Import::DBI::GenericOperation::VERSION  = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( table db where );
SPOPS::Import::DBI::GenericOperation->mk_accessors( @FIELDS );

sub add_where_params {
    my ( $self, @args ) = @_;
    push @{ $self->{where_params} }, @args;
}

sub where_params {
    my ( $self, $all_args ) = @_;
    if ( $all_args ) {
        $self->{where_params} = ( ref $all_args )
                                  ? $all_args : [ $all_args ];
    }
    return $self->{where_params};
}

########################################
# Core API

sub get_fields { return ( $_[0]->SUPER::get_fields(), @FIELDS ) }

sub run {
    my ( $self ) = @_;

    unless ( $self->db )     { spops_error "Cannot run without a database handle available" }
    unless ( $self->table )  { spops_error "Cannot run without table defined" }
    unless ( $self->where )  { spops_error "Cannot run without where clause defined" }

    my %op_args = (
        db    => $self->db,
        table => $self->table,
        where => $self->where,
        value => $self->where_params,
    );
    my $rv = eval { $self->_run_operation( \%op_args ) };
    return ( $@ ) ? [ [ undef, $rv, $@ ] ]
                  : [ [ 1, $rv, undef ] ];
}

sub _run_operation {
    my ( $self ) = @_;
    die "'", ref( $self ), "' does not implement the required ",
        "method '_run_operation()'";
}

########################################
# For subclasses...

sub data_from_file {
    my ( $self, $filename ) = @_;
    $self->assign_data( $self->raw_data_from_file( $filename ) );
}


sub data_from_fh {
    my ( $self, $fh ) = @_;
    $self->assign_data( $self->raw_data_from_fh( $fh ) );
}


sub assign_raw_data {
    my ( $self, $metadata ) = @_;
    for ( qw( where table where_params ) ) {
        $self->$_( $metadata->{$_} );
        delete $metadata->{ $_ };
    }
    $self->extra_metadata( $metadata );
    return $self;
}

1;

__END__

=head1 NAME

SPOPS::Import::DBI::GenericOperation - Base class for delete and update import operations

=head1 SYNOPSIS

 use base qw( SPOPS::Import::DBI::GenericOperation );
 
 sub _run_operation {
     my ( $self, $op_args ) = @_;
     ...
 }

=head1 DESCRIPTION

This class provides most of the functionality necessary to delete and
remove, including the main method C<run()>. Subclasses just need to
override C<_run_operation()>.

=head1 METHODS

=head2 Subclassing

B<_run_operation( \%import_params )>

Subclasses must implement this to perform the actual operation. The
arguments available in C<\%import_params> are:

=over 4

=item *

B<db>: Database handle

=item *

B<table>: Name of the table

=item *

B<where>: WHERE clause

=item *

B<value>: Arrayref of values for use in the WHERE clause, added by
C<add_where_params()>

=back

=head2 Implementations

B<add_where_params( @params )>

Bound parameters for the WHERE clause. Each will be bound in turn.

B<data_from_file( $filename )>

Runs C<raw_data_from_file( $filename )> from L<SPOPS::Import> to read
a serialized Perl data structure from C<$filename>, then sends the
arrayref to C<assign_data()> and returns the result.

B<data_from_fh( $filehandle )>

Runs C<raw_data_from_fh( $filename )> from L<SPOPS::Import> to read a
serialized Perl data structure from C<$filehandle>, then sends the
arrayref to C<assign_data()> and returns the result.

B<assign_data( \%metadata )>

Assigns the data 'table', 'where' and 'where_params' from
C<\%metadata> to the import object.

The additional metadata is stored under the 'extra_metadata' property
of the import object.

=head1 COPYRIGHT

Copyright (c) 2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
