package SPOPS::Export::SQL;

# $Id: SQL.pm,v 3.3 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base qw( SPOPS::Export );

$SPOPS::Export::SQL::VERSION  = sprintf("%d.%02d", q$Revision: 3.3 $ =~ /(\d+)\.(\d+)/);

use constant DEFAULT_RECORD_DELIMETER => ';';

my @FIELDS = qw( table_name record_delimiter );
SPOPS::Export::SQL->mk_accessors( @FIELDS );

sub initialize {
    my ( $self, $params ) = @_;
    $self->record_delimiter || $self->record_delimiter( DEFAULT_RECORD_DELIMETER );
    return $self;
}

sub get_fields { return ( $_[0]->SUPER::get_fields, @FIELDS ) }

sub create_record {
    my ( $self, $object, $fields ) = @_;
    my $object_class = $self->object_class;
    my $table = $self->table_name ||
                $self->table_name( $object_class->table_name );
    unless ( $table ) {
        SPOPS::Exception->throw(
                    "No table name set (via \$exporter->table_name( \$table ))\n" .
                    " and your object class ($object_class) does not have a\n" .
                    "table name associated with it. No records exported" );
    }
    my @values = map { $self->serialize_field_data( $object->{ $_ } ) } @{ $fields };
    my $field_text = join( ', ', @{ $fields } );
    my $value_text = join( ', ', @values );
    my $delimiter  = $self->record_delimiter;
    return <<SQL;
INSERT INTO $table ( $field_text )
VALUES ( $value_text ) $delimiter
SQL
}


sub serialize_field_data {
    my ( $self, $data ) = @_;
    $data =~ s/\'/\\\'/g;
    return "'$data'";
}

1;

__END__

=head1 NAME

SPOPS::Export::SQL - Export SPOPS objects as a series of SQL statements

=head1 SYNOPSIS

 # See SPOPS::Export

=head1 DESCRIPTION

Implement SQL output for L<SPOPS::Export|SPOPS::Export>.

=head1 PROPERTIES

B<table_name>

The name of the table to use in the export. If not set we use the
table used by the object class. If we cannot find a table name in the
object class (via a method C<table_name()>) then we die.

B<record_delimiter>

The string to use to delimit SQL statements. Default is ';', but you
might want to use '\g' or other string depeneding on your database.

=head1 METHODS

B<create_record( $object, $fields )>

Return a SQL statement suitable for importing into a database to
create a record using an 'INSERT'.

B<serialize_field_data( $data )>

Return a quoted, escaped string suitable for putting into a runnable
SQL statement. For example:

 my $value = $exporter->serialize_field_data( "O'Reilly and Associates" );

Returns by default:

 'O\'Reilly and Associates'

Just subclass this class and override the method of your database uses
different quoting schemes.

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
