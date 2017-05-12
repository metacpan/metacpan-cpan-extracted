#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2014 -- leonerd@leonerd.org.uk

package Net::Async::CassandraCQL::Query;

use strict;
use warnings;

our $VERSION = '0.12';

use Carp;

use Devel::GlobalDestruction qw( in_global_destruction );

=head1 NAME

C<Net::Async::CassandraCQL::Query> - a Cassandra CQL prepared query

=head1 DESCRIPTION

Prepared query objects are returned by the C<prepare> of
L<Net::Async::CassandraCQL> to represent a prepared query in the server. They
can be executed multiple times, if required, by passing the values of the
placeholders to the C<execute> method.

For backward compatibility, as this object class is no longer a subclass of
L<Protocol::CassandraCQL::ColumnMeta>, the following methods will be directed
to the C<params_meta> instance.

 columns column_name column_shortname column_type find_column
 encode_data decode_data

However, most of them are available more directly as the C<param*> methods.
Code should not rely on these temporary redirects remaining in a future
version.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = bless {
      cassandra   => $args{cassandra},
      cql         => $args{cql},
      id          => $args{id},
      params_meta => $args{params_meta},
      result_meta => $args{result_meta},
   }, $class;

   return $self;
}

sub DESTROY
{
   return if in_global_destruction;
   my $self = shift;
   my $cass = $self->{cassandra} or return;

   $cass->_expire_query( $self->cql );
}

=head1 METHODS

=cut

foreach my $method (qw( columns column_name column_shortname column_type find_column
                        encode_data decode_data )) {
   no strict 'refs';
   *$method = sub {
      my $self = shift;
      $self->params_meta->$method( @_ )
   };
}

=head2 $id = $query->id

Returns the query ID.

=cut

sub id
{
   my $self = shift;
   return $self->{id};
}

=head2 $cql = $query->cql

Returns the original query string used to prepare the query.

=cut

sub cql
{
   my $self = shift;
   return $self->{cql};
}

=head2 $meta = $query->params_meta

Returns a L<Protocol::CassandraCQL::ColumnMeta> instance with the metadata
about the bind parameters.

=cut

sub params_meta
{
   my $self = shift;
   return $self->{params_meta};
}

=head2 $n_params = $query->params

=head2 $name = $query->param_name( $idx )

=head2 ( $keyspace, $table, $column ) = $query->param_name( $idx )

=head2 $name = $query->param_shortname( $idx )

=head2 $type = $query->param_type( $idx )

Redirections to the appropriately named method on the C<params_meta> object.

=cut

sub params          { shift->params_meta->columns }
sub param_name      { shift->params_meta->column_name( @_ ) }
sub param_shortname { shift->params_meta->column_shortname( @_ ) }
sub param_type      { shift->params_meta->column_type( @_ ) }

=head2 $meta = $query->result_meta

Returns a L<Protocol::CassandraCQL::ColumnMeta> instance with the metadata
about the query result. This will only be defined on connections with a
C<cql_version> of 2 or above.

=cut

sub result_meta
{
   my $self = shift;
   return $self->{result_meta};
}

=head2 $query->execute( $data, $consistency ) ==> ( $type, $result )

Executes the query on the Cassandra connection object that created it,
returning a future yielding the result the same way as the C<query> or
C<execute> methods.

The contents of the C<$data> reference will be encoded according to the types
given in the underlying column metadata. C<$data> may be given as a positional
ARRAY reference, or a named HASH reference where the keys give column names.

=cut

sub execute
{
   my $self = shift;
   my ( $data, $consistency ) = @_;

   my $params_meta = $self->params_meta;

   my @data;
   if( ref $data eq "ARRAY" ) {
      @data = @$data;
   }
   elsif( ref $data eq "HASH" ) {
      @data = ( undef ) x $params_meta->columns;
      foreach my $name ( keys %$data ) {
         my $idx = $params_meta->find_column( $name );
         defined $idx or croak "Unknown bind column name '$name'";
         defined $data[$idx] and croak "Cannot bind column ".$params_meta->column_name($idx)." twice";
         $data[$idx] = $data->{$name};
      }
   }

   my @bytes = $params_meta->encode_data( @data );

   return $self->{cassandra}->execute(
      $self, \@bytes, $consistency,
      skip_metadata => defined $self->result_meta,
   )->on_done( sub {
      my ( $type, $result ) = @_;

      $result->set_metadata( $self->result_meta ) if $result and !$result->has_metadata;
   });
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
