package SPOPS::Import::DBI::Data;

# $Id: Data.pm,v 3.6 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base qw( SPOPS::Import );
use SPOPS::Exception qw( spops_error );
use SPOPS::SQLInterface;

$SPOPS::Import::DBI::Data::VERSION  = sprintf("%d.%02d", q$Revision: 3.6 $ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( table fields db );
SPOPS::Import::DBI::Data->mk_accessors( @FIELDS );

########################################
# Core API

sub get_fields { return ( $_[0]->SUPER::get_fields(), @FIELDS ) }

sub run {
    my ( $self ) = @_;
    unless ( $self->db )     { spops_error "Cannot run without a database handle available" }
    unless ( $self->table )  { spops_error "Cannot run without table defined" }
    unless ( $self->fields ) { spops_error "Cannot run without fields defined" }
    unless ( $self->data )   { spops_error "Cannot run without data defined" }

    my %insert_args = ( db    => $self->db,
                        table => $self->table,
                        field => $self->fields, );
    my @status = ();
    foreach my $data ( @{ $self->data } ) {
        $insert_args{value} = $data;
        my $rv = eval { SPOPS::SQLInterface->db_insert( \%insert_args ) };
        if ( $@ ) {
            push @status, [ undef, $data, $@ ];
        }
        else {
            push @status, [ 1, $data, undef ];
        }
    }
    return \@status;
}

########################################
# Property manipulation

sub fields_as_hashref {
    my ( $self ) = @_;
    my $field_list = $self->fields;
    unless ( ref $field_list eq 'ARRAY' and scalar @{ $field_list } ) {
        spops_error "Before using this method, please set the fields in the " .
                    "importer object using:\n\$importer->fields( \\\@fields )";
    }
    my $count = 0;
    return { map { $_ => $count++ } @{ $field_list } };
}

########################################
# I/O and property assignment

sub data_from_file {
    my ( $self, $filename ) = @_;
    $self->assign_raw_data( $self->raw_data_from_file( $filename ) );
}


sub data_from_fh {
    my ( $self, $fh ) = @_;
    $self->assign_raw_data( $self->raw_data_from_fh( $fh ) );
}


sub assign_raw_data {
    my ( $self, $raw_data ) = @_;
    my $meta = shift @{ $raw_data };
    $self->table( $meta->{table} || $meta->{sql_table} );
    $self->fields( $meta->{fields} || $meta->{field_order} );
    $self->data( $raw_data );
    delete $meta->{ $_ } for ( qw( table sql_table fields field_order ) );
    $self->extra_metadata( $meta );
    return $self;
}

1;

__END__

=head1 NAME

SPOPS::Import::DBI::Data - Import raw data to a DBI table

=head1 SYNOPSIS

 #!/usr/bin/perl

 use strict;
 use DBI;
 use SPOPS::Import;

 {
     my $dbh = DBI->connect( 'DBI:Pg:dbname=test' );
     $dbh->{RaiseError} = 1;

     my $table_sql = qq/
       CREATE TABLE import ( import_id SERIAL,
                             name varchar(50),
                             bad int,
                             good int,
                             disco int ) /;
     $dbh->do( $table_sql );

     my $importer = SPOPS::Import->new( 'dbdata' );
     $importer->db( $dbh );
     $importer->table( 'import' );
     $importer->fields( [ 'name', 'bad', 'good', 'disco' ] );
     $importer->data( [ [ 'Saturday Night Fever', 5, 10, 15 ],
                        [ 'Grease', 12, 5, 2 ],
                        [ "You Can't Stop the Music", 15, 0, 12 ] ] );
     my $status = $importer->run;
     foreach my $entry ( @{ $status } ) {
         if ( $entry->[0] ) { print "$entry->[1][0]: OK\n" }
         else               { print "$entry->[1][0]: FAIL ($entry->[2])\n" }
     }

     $dbh->do( 'DROP TABLE import' );
     $dbh->do( 'DROP SEQUENCE import_import_id_seq' );
     $dbh->disconnect;
}

=head1 DESCRIPTION

Import raw (non-object) data to a DBI table.

=head1 METHODS

B<data_from_file( $filename )>

Runs C<raw_data_from_file( $filename )> from L<SPOPS::Import> to read
a serialized Perl data structure from C<$filename>, then sends the
arrayref to C<assign_raw_data()> and returns the result.

B<data_from_fh( $filehandle )>

Runs C<raw_data_from_fh( $filename )> from L<SPOPS::Import> to read a
serialized Perl data structure from C<$filehandle>, then sends the
arrayref to C<assign_raw_data()> and returns the result.

B<assign_raw_data( \@( \%metadata, @data ) )>

Assigns the data 'table' and 'fields' from C<\%metadata> to the import
object, then the remainder of the data to the 'data' property.

The additional metadata is stored under the 'extra_metadata' property
of the import object.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
