package SPOPS::Import::Object;

# $Id: Object.pm,v 3.7 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base qw( SPOPS::Import );
use SPOPS::Exception qw( spops_error );

$SPOPS::Import::Object::VERSION  = sprintf("%d.%02d", q$Revision: 3.7 $ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( include_id fields ); # skip_fields 
SPOPS::Import::Object->mk_accessors( @FIELDS );


########################################;
# Core API

sub get_fields { return ( $_[0]->SUPER::get_fields(), @FIELDS ) }

sub run {
    my ( $self ) = @_;
    my $fields       = $self->fields;
    my $object_class = $self->object_class;
    unless ( $fields )       { spops_error "Cannot run without fields defined" }
    unless ( $object_class ) { spops_error "Cannot run without object class defined" }
    my $all_data = $self->data;
    unless ( ref( $all_data ) eq 'ARRAY' and scalar @{ $all_data } > 0 ) {
        spops_error "Cannot run without data defined";
    }

    my $num_fields = scalar @{ $fields };
    my @status = ();
    foreach my $data ( @{ $all_data } ) {
        my $obj = $object_class->new;
        for ( my $i = 0; $i < $num_fields; $i++ ) {
            $obj->{ $fields->[ $i ] } = $data->[ $i ];
        }
        eval {
            $obj->save({ is_add => 1,
                         DEBUG  => $self->DEBUG })
        };
        if ( $@ ) {
            push @status, [ undef, $data, $@ ];
        }
        else {
            push @status, [ 1, $obj, undef ];
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
        spops_error 'Please set the fields in the importer object using: ',
                    '\$importer->fields( \\\@fields" )';
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


# Note that we support 'spops_class' and 'field_order' below for
# backward compatibility

sub assign_raw_data {
    my ( $self, $raw_data_orig ) = @_;
    my @raw_data = @{ $raw_data_orig };
    my %meta = %{ shift @raw_data };
    $self->object_class( $meta{object_class} || $meta{spops_class} );
    $self->fields( $meta{fields} || $meta{field_order} );
    delete $meta{ $_ } for( qw( object_class spops_class fields field_order ) );
    $self->extra_metadata( \%meta );
    $self->data( \@raw_data );
    return $self;
}

1;

__END__

=head1 NAME

SPOPS::Import::Object - Import SPOPS objects

=head1 SYNOPSIS

 # Define a data file 'mydata.dat'
 
 [
    { spops_class => 'OpenInteract2::Security',
      field_order => [ qw/ class object_id scope scope_id security_level / ],
      transform_default_to_id    => [ 'scope_id' ] },
    [ 'OpenInteract2::Action::Error', 0, 'w', 'world', 4 ],
    [ 'OpenInteract2::Action::Error', 0, 'g', 'site_admin_group', 8 ],
 ];
 
 # Create the importer and read in the properties and data
 
 my $importer = SPOPS::Import->new( 'object' )
                             ->data_from_file( 'mydata.dat' );
 
 # Modify the 'name' field in every record
 
 my $fields_h = $importer->fields_as_hashref;
 my $name_idx = $fields_h->{name};
 foreach my $data ( @{ $importer->data } ) {
     $data->[ $name_idx ] =~ s/YourClass/MyClass/;
 }
 
 # Run the import and display the results
 
 my $status = $importer->run;
 foreach my $entry ( @{ $status } ) {
   if ( $entry->[0] ) { print "$entry->[1][0]: OK\n" }
   else               { print "$entry->[1][0]: FAIL ($entry->[2])\n" }
 }

=head1 DESCRIPTION

This class implements simple data import for SPOPS objects using a
serialized Perl data structure for the data storage.

For more information on SPOPS importing in general, see
L<SPOPS::Manual::ImportExport|SPOPS::Manual::ImportExport> and
L<SPOPS::Import|SPOPS::Import>.

=head1 METHODS

B<fields_as_hashref()>

Translate the field arrayref (returned by the C<fields()> call) into a
hashref of fieldname to position in data record. This is useful if you
want to modify the data after they have been read in -- since the data
are position- rather than name-indexed, you will need to map the name
to the index.

So you you had:

 my $fields = $importer->fields
 print Dumper( $fields );
 my $fields_h = $importer->fields_as_hashref;
 print Dumper( $fields_h );

You might wind up with:

  $VAR1 = [
          'first',
          'second',
          'third',
          'fourth'
          ];
  $VAR1 = {
          'first' => 0,
          'fourth' => 3,
          'third' => 2,
          'second' => 1
          };

B<data_from_file( $filename )>

Read the metadata and data from C<$filename>. Runs
C<assign_raw_data()> to put the information into the object.

B<data_from_fh( $fh )>

Read the metadata and data from the filehandle C<$fh>. Runs
C<assign_raw_data()> to put the information into the object.

B<assign_raw_data( \@raw_data )>

Assigns the raw data C<\@raw_data> to the object. The first item
should be metadata, and all remaining items are the data to be
inserted.

The metadata should at least have the keys C<object_class> and
C<fields> (or C<spops_class> and C<field_order>, respectively, for
backward compatibility).

Other metadata you include is available through the C<extra_metadata>
property. These metadata might be for application-specific purposes.

After this is run the object should have available for inspection the
following properties:

=over 4

=item *

B<object_class>

=item *

B<fields>

=item *

B<data>

=back

=head1 SEE ALSO

L<SPOPS::Manual::ImportExport|SPOPS::Manual::ImportExport>

L<SPOPS::Import|SPOPS::Import>

L<SPOPS::Export::Object|SPOPS::Export::Object>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
