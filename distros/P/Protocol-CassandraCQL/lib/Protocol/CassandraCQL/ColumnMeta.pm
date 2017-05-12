#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2014 -- leonerd@leonerd.org.uk

package Protocol::CassandraCQL::ColumnMeta;

use strict;
use warnings;

our $VERSION = '0.12';

use Carp;

use Protocol::CassandraCQL qw( :rowflags );
use Protocol::CassandraCQL::Type;

=head1 NAME

C<Protocol::CassandraCQL::ColumnMeta> - stores the column metadata of a Cassandra CQL query

=head1 DESCRIPTION

Objects in this class interpret the column metadata from a message frame
containing a C<OPCODE_RESULT> response to a query giving C<RESULT_ROWS> or
C<RESULT_PREPARED>. It provides lookup of column names and type information,
and provides a convenient accessor to the encoding and decoding support
functions, allowing encoding of bytestrings from perl data when executing a
prepared statement, and decoding of bytestrings to perl data when obtaining
query results.

It is also subclassed as L<Protocol::CassandraCQL::Result>.

=cut

=head1 CONSTRUCTORS

=cut

=head2 $meta = Protocol::CassandraCQL::ColumnMeta->from_frame( $frame, $version )

Returns a new column metadata object initialised from the given message frame
at the given CQL version number. (Version will default to 1 if not supplied,
but this may become a required parameter in a future version).

=cut

sub from_frame
{
   my $class = shift;
   my ( $frame, $version ) = @_;

   defined $version or $version = 1;

   my $self = bless {}, $class;

   $self->{columns} = \my @columns;

   my $flags     = $frame->unpack_int;
   my $n_columns = $frame->unpack_int;

   my $has_gts = $flags & ROWS_HAS_GLOBALTABLESPEC;

   my $has_paging  = ( $version > 1 ) && ( $flags & ROWS_HAS_MORE_PAGES );
   my $no_metadata = ( $version > 1 ) && ( $flags & ROWS_NO_METADATA );

   if( $has_paging ) {
      $self->{paging_state} = $frame->unpack_bytes;
   }

   if( $no_metadata ) {
      push @columns, undef for 1 .. $n_columns;
   }
   else {
      my @gts = $has_gts ? ( $frame->unpack_string, $frame->unpack_string )
                         : ();

      foreach ( 1 .. $n_columns ) {
         my @keyspace_table = $has_gts ? @gts : ( $frame->unpack_string, $frame->unpack_string );
         my $colname        = $frame->unpack_string;
         my $type           = Protocol::CassandraCQL::Type->from_frame( $frame );

         my @col = ( @keyspace_table, $colname, undef, $type );

         push @columns, \@col;
      }

      $self->_set_shortnames;
   }

   return $self;
}

=head2 $meta = Protocol::CassandraCQL::ColumnMeta->new( %args )

Returns a new column metadata object initialised directly from the given
column data. This constructor is intended for use by unit test scripts, to
create metadata directly from mocked connection objects or similar.

It takes the following named arguments:

=over 8

=item columns => ARRAY[ARRAY[STR, STR, STR, STR]]

An ARRAY reference containing the data about individual columns. Each row is
represented by an ARRAY reference containing four strings; giving the three
components of its name, and the name of its type:

 [ $keyspace, $table, $column, $typename ]

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = bless {}, $class;

   $self->{columns} = \my @columns;

   foreach my $c ( @{ $args{columns} } ) {
      push @columns, [
         @{$c}[0,1,2], # name
         undef,        # shortname
         Protocol::CassandraCQL::Type->from_name( $c->[3] ),
      ];
   }

   $self->_set_shortnames;

   return $self;
}

sub _set_shortnames
{
   my $self = shift;

   my $columns = $self->{columns};

   foreach my $idx ( 0 .. $#$columns ) {
      my $c = $columns->[$idx];
      my @names;

      my $name = "$c->[0].$c->[1].$c->[2]";
      push @names, $name;

      $name = "$c->[1].$c->[2]";
      push @names, $name if 1 == grep { "$_->[1].$_->[2]" eq $name } @$columns;

      $name = $c->[2];
      push @names, $name if 1 == grep { $_->[2] eq $name } @$columns;

      $c->[3] = $names[-1];
      $self->{name_to_col}{$_} = $idx for @names;
   }
}

=head1 METHODS

=cut

=head2 $n = $meta->columns

Returns the number of columns

=cut

sub columns
{
   my $self = shift;
   return scalar @{ $self->{columns} };
}

=head2 $name = $meta->column_name( $idx )

=head2 ( $keyspace, $table, $column ) = $meta->column_name( $idx )

Returns the name of the column at the given (0-based) index; either as three
separate strings, or all joined by ".".

=cut

sub column_name
{
   my $self = shift;
   my ( $idx ) = @_;

   croak "No such column $idx" unless $idx >= 0 and $idx < @{ $self->{columns} };
   my @n = @{ $self->{columns}[$idx] }[0..2];

   return @n if wantarray;
   return join ".", @n;
}

=head2 $name = $meta->column_shortname( $idx )

Returns the short name of the column; which will be just the column name
unless it requires the table or keyspace name as well to make it unique within
the set.

=cut

sub column_shortname
{
   my $self = shift;
   my ( $idx ) = @_;

   croak "No such column $idx" unless $idx >= 0 and $idx < @{ $self->{columns} };
   return $self->{columns}[$idx][3];
}

=head2 $type = $meta->column_type( $idx )

Returns the type of the column at the given index as an instance of
L<Protocol::CassandraCQL::Type>.

=cut

sub column_type
{
   my $self = shift;
   my ( $idx ) = @_;

   croak "No such column $idx" unless $idx >= 0 and $idx < @{ $self->{columns} };
   return $self->{columns}[$idx][4];
}

=head2 $idx = $meta->find_column( $name )

Returns the index of the given named column. The name may be given as
C<keyspace.table.column>, or C<table.column> or C<column> if they are unique
within the set. Returns C<undef> if no such column exists.

=cut

sub find_column
{
   my $self = shift;
   my ( $name ) = @_;

   return $self->{name_to_col}{$name};
}

=head2 @bytes = $meta->encode_data( @data )

Returns a list of encoded bytestrings from the given data according to the
type of each column. Checks each value is valid; if not throws an exception
explaining which column failed and why.

An exception is thrown if the wrong number of values is passed.

=cut

sub encode_data
{
   my $self = shift;
   my @data = @_;

   my $n = @{ $self->{columns} };
   croak "Too many values" if @data > $n;
   croak "Not enough values" if @data < $n;

   foreach my $i ( 0 .. $#data ) {
      my $e = $self->column_type( $i )->validate( $data[$i] ) or next;

      croak "Cannot encode ".$self->column_shortname( $i ).": $e";
   }

   return map { defined $data[$_] ? $self->column_type( $_ )->encode( $data[$_] ) : undef }
          0 .. $n-1;
}

=head2 @data = $meta->decode_data( @bytes )

Returns a list of decoded data from the given encoded bytestrings according to
the type of each column.

=cut

sub decode_data
{
   my $self = shift;
   my @bytes = @_;

   return map { defined $bytes[$_] ? $self->column_type( $_ )->decode( $bytes[$_] ) : undef }
          0 .. $#bytes;
}

=head2 $bytes = $meta->paging_state

Returns the CQLv2+ paging state, if it was contained in the given frame. This
would be returned in an C<OPCODE_RESULT> message to a query or execute request
that requested paging.

=cut

sub paging_state
{
   my $self = shift;
   return $self->{paging_state};
}

=head2 $bool = $meta->has_metadata

Returns a boolean indicating whether the column metadata (field names and
types) is actually defined. Normally this would be true, except if the object
is an instance of L<Protocol::CassandraCQL::Result> returned by executing a
prepared statement with metadata specifically disabled.

=cut

sub has_metadata
{
   my $self = shift;
   return defined $self->{columns}[0];
}

=head1 SPONSORS

This code was paid for by

=over 2

=item *

Perceptyx L<http://www.perceptyx.com/>

=item *

Shadowcat Systems L<http://www.shadow.cat>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
