package SPOPS::Import;

# $Id: Import.pm,v 3.8 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base qw( Class::Accessor Class::Factory );
use SPOPS::Exception qw( spops_error );

$SPOPS::Import::VERSION  = sprintf("%d.%02d", q$Revision: 3.8 $ =~ /(\d+)\.(\d+)/);

use constant AKEY => '_attrib';

my @FIELDS = qw( object_class data extra_metadata DEBUG );
SPOPS::Import->mk_accessors( @FIELDS );

sub new {
    my ( $pkg, $type, $params ) = @_;
    my $class = eval { $pkg->get_factory_class( $type ) };
    spops_error $@ if ( $@ );
    my $self = bless( {}, $class );;
    foreach my $field ( $self->get_fields ) {
        $self->$field( $params->{ $field } );
    }
    return $self->initialize( $params );
}

sub initialize { return $_[0] }

sub get_fields { return @FIELDS }

# Class::Accessor stuff

sub get { return $_[0]->{ AKEY() }{ $_[1] } }
sub set { return $_[0]->{ AKEY() }{ $_[1] } = $_[2] }

sub run {
    my $class = ref $_[0] || $_[0];
    spops_error "SPOPS::Import subclass [$class] must implement run()";
}


########################################
# I/O
########################################

# Read import data from a file; the first item is metadata, the
# remaining ones are data. Subclasses should override and call

sub raw_data_from_file {
    my ( $class, $filename ) = @_;
    my $raw_data = $class->read_perl_file( $filename );
    unless ( ref $raw_data eq 'ARRAY' ) {
        spops_error "Raw data must be in arrayref format.";
    }
    return $raw_data;
}


sub raw_data_from_fh {
    my ( $class, $fh ) = @_;
    no strict 'vars';
    my $raw = $class->read_fh( $fh );
    my $data = eval $raw;
    if ( $@ ) {
        spops_error "Cannot parse data from filehandle: [$@]";
    }
    unless ( ref $data eq 'ARRAY' ) {
        spops_error "Data must be in arrayref format";
    }
    return $data;
}


# Read in a file and evaluate it as perl.

sub read_perl_file {
    my ( $class, $filename ) = @_;
    no strict 'vars';
    my $raw  = $class->read_file( $filename );
    my $data = eval $raw;
    if ( $@ ) {
        spops_error "Cannot parse data file ($filename): $@";
    }
    return $data;
}


# Read in a file and return the contents

sub read_file {
    my ( $class, $filename ) = @_;

    unless ( -f $filename ) {
        spops_error "Cannot read: [$filename] does not exist";
    }
    open( DF, $filename ) ||
                    spops_error "Cannot read data file: $!";
    local $/ = undef;
    my $raw = <DF>;
    close( DF );
    return $raw;
}


sub read_fh {
    my ( $class, $fh ) = @_;
    local $/ = undef;
    my $raw = <$fh>;
    return $raw;
}


##############################
# INITIALIZE

__PACKAGE__->register_factory_type( object   => 'SPOPS::Import::Object' );
__PACKAGE__->register_factory_type( dbdata   => 'SPOPS::Import::DBI::Data' );
__PACKAGE__->register_factory_type( dbupdate => 'SPOPS::Import::DBI::Update' );
__PACKAGE__->register_factory_type( dbdelete => 'SPOPS::Import::DBI::Delete' );
__PACKAGE__->register_factory_type( table    => 'SPOPS::Import::DBI::Table' );
1;

__END__

=head1 NAME

SPOPS::Import - Factory and parent for importing SPOPS objects

=head1 SYNOPSIS

 my $importer = SPOPS::Import->new( 'object' );
 $importer->object_class( 'My::Object' );
 $importer->fields( [ 'name', 'title', 'average' ] );
 $importer->data( [ [ 'Steve', 'Carpenter', '160' ],
                    [ 'Jim', 'Engineer', '178' ],
                    [ 'Mario', 'Center', '201' ] ]);
 $importer->run;

=head1 DESCRIPTION

This class is a factory class for creating importer objects. It is
also the parent class for the importer objects.

=head1 METHODS

=head2 I/O

B<read_file( $filename )>

Reads a file from C<$filename>, returning the content.

B<read_perl_file( $filename )>

Reads a file from C<$filename>, then does an L<eval|eval> on the
content to get back a Perl data structure. (Normal string C<eval>
caveats apply.)

Returns the Perl data structure.

B<read_fh( $filehandle )>

Reads all (or remaining) information from C<$filehandle>, returning
the content.

B<raw_data_from_file( $filename )>

Reads C<$filename> as a Perl data structure and does perliminary
checks to ensure it can be used in an import.

B<raw_data_from_fh( $filehandle )>

Reads C<$filehandle> as a Perl data structure and does perliminary
checks to ensure it can be used in an import.

=head2 Properties

B<object_class>

Class of the object to import

B<data>

Data for this import. The implementation subclass specifies its
format, but it is normally either an arrayref of arrayrefs or an
arrayref of hashrefs.

B<extra_metadata>

Placeholder for user-defined metadata.

=head2 Subclasses

Subclasses should override the following methods.

B<run()>

Runs the import and, unless otherwise specified, returns an arrayref
of status entries, one for each record it tried to import.

Each status entry is an arrayref formatted:

 [ status (boolean), record, message ]

If the import for this record was successful, the first (0) entry will
be true, the second (1) will be the object inserted (if possible,
otherwise it is the data structure as if the record failed), and the
third (2) entry will be undefined.

If the import for this record failed, the first (0) entry will be
undefined, the second (1) will be the data structure we tried to insert,
and the third (2) entry will contain an error message.

Whether the import succeeds or fails, the second entry will contain
the record we tried to import. The record is an arrayref, and if you
want to map the values to fields just ask the importer object for its
fields:

 my $field_name = $importer->fields->[1];
 
 # On a success (if possible):
 
 foreach my $item ( @{ $status } ) {
     print "Value of $field_name: ", $item->[1]->$field_name(), "\n";
 }
 
 # On a failure (or success, if not possible):
 
 foreach my $item ( @{ $status } ) {
    print "Value of $field_name: $item->[1][1]\n";
 }

=head1 BUGS

None known.

=head1 TO DO

B<Import XML>

We currently export XML documents but we do not import them. It would
be useful to do this.

=head1 SEE ALSO

L<SPOPS::Manual::ImportExport|SPOPS::Manual::ImportExport>

L<Class::Accessor|Class::Accessor>

L<Class::Factory|Class::Factory>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
