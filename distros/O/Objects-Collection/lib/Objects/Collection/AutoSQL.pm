package Objects::Collection::AutoSQL;

=head1 NAME

 Objects::Collection::AutoSQL - class for collections of data, stored in database.

=head1 SYNOPSIS

  use Objects::Collection::AutoSQL;
  my $metaobj = new Objects::Collection::AutoSQL::
           dbh => $dbh,         #database connect
           table => 'metadata', #table name
           field=> 'mid',       #key field (IDs), usually primary,autoincrement
           cut_key =>1,         #delete field mid from readed records, 
                                #or delete_key=>1
           sub_ref =>
              #callback for create objects for readed records
              sub { my $id = shift; new MyObject:: shift }
             
=head1 DESCRIPTION

Provide simply access to records, with unique field.

For exampe:

 HAVE mysql table:

 mysql> \u orders
 mysql> select * from beers;
 +-----+--------+-----------+
 | bid | bcount | bname     |
 +-----+--------+-----------+
 |   1 |      1 | heineken  |
 |   2 |      1 | broadside |
 |   3 |      2 | tiger     |
 |   4 |      2 | castel    |
 |   5 |      3 | karhu     |
 +-----+--------+-----------+
 5 rows in set (0.00 sec)

 my $beers = new Objects::Collection::AutoSQL::
  dbh     => $dbh,          #database connect
  table   => 'beers',       #table name
  field   => 'bid',         #key field (IDs), usually primary,autoincrement
  cut_key => 1;             #delete field 'bid' from readed records,


 my $heineken = $beers->fetch_object(1);
 #SELECT * FROM beers WHERE bid in (1)

 print Dumper($heineken);

 ...

      $VAR1 = {
             'bcount' => '1',
             'bname' => 'heineken'
              };
 ...
 
 $heineken->{bcount}++;

 my $karhu = $beers->fetch_object(5);
 #SELECT * FROM beers WHERE bid in (5)
 
 $karhu->{bcount}++;
 
 $beers->store_changed;
 #UPDATE beers SET bcount='2',bname='heineken' where bid=1
 #UPDATE beers SET bcount='4',bname='karhu' where bid=5

 my $hash = $beers->fetch_objects({bcount=>[4,1]});
 #SELECT * FROM beers WHERE  ( bcount in (4,1) )
 
 print Dumper($hash);
 
 ...

 $VAR1 = {
          '2' => {
                   'bcount' => '1',
                   'bname' => 'broadside'
                 },
          '5' => {
                   'bcount' => '4',
                   'bname' => 'karhu'
                 }
        };

  ...



=head1 METHODS

=cut

use strict;
use warnings;
use Data::Dumper;
use Carp;
use Objects::Collection;
use Objects::Collection::Base;
use Objects::Collection::ActiveRecord;
@Objects::Collection::AutoSQL::ISA     = qw(Objects::Collection);
$Objects::Collection::AutoSQL::VERSION = '0.02';
attributes qw( _dbh _table_name _key_field _is_delete_key_field _sub_ref);

sub _init {
    my $self = shift;
    my %arg  = @_;
    $self->_dbh( $arg{dbh} );
    $self->_table_name( $arg{table} );
    $self->_key_field( $arg{field} );
    $self->_is_delete_key_field( $arg{delete_key} || $arg{cut_key} );
    $self->_sub_ref( $arg{sub_ref} );
    $self->SUPER::_init(@_);
}

=head2 get_dbh

 Return current $dbh.

=cut

sub get_dbh {
    return $_[0]->_dbh;
}

=head2 get_ids_where(<SQL where  expression>)

Return ref to ARRAY of readed IDs.

=cut

sub get_ids_where {
    my $self       = shift;
    my $where      = shift || return [];
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $query      = "SELECT $field FROM $table_name WHERE $where";
    return ( $dbh->selectcol_arrayref($query) || [] );
}

sub after_load {
    my $self = shift;
    return $_[0];
}

sub before_save {
    my $self = shift;
    return $_[0];
}

sub _query_dbh {
    my $self  = shift;
    my $query = shift;
    my $dbh   = $self->_dbh;
    my $sth   = $dbh->prepare($query) or croak $dbh::errstr. "\nSQL: $query";
    $sth->execute or croak $dbh::errstr. "\nSQL: $query";
    return $sth;
}

sub _store {
    my ( $self, $ref ) = @_;
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    while ( my ( $key, $rec_ref ) = each %$ref ) {
        my $tmp_val  = ref($rec_ref) eq 'HASH' ? $rec_ref : $rec_ref->_get_attr;
        my $prepared = $self->before_save($tmp_val);
        my @rows     = ref($prepared) eq 'ARRAY' ? @$prepared : ($prepared);
        foreach my $val (@rows) {
            my @records =
              map {
                [ $_, $dbh->quote( defined( $val->{$_} ) ? $val->{$_} : '' ) ]
              }
              keys %$val;
            my $query =
                "UPDATE $table_name SET "
              . join( ",", map { qq!$_->[0]=$_->[1]! } @records )
              . " where $field=$key";
            $self->_query_dbh($query);
        }    #foreach
    }    #while
}
=head2 _prepare_where <query hash>

return <where>  expression or undef else

=cut
sub _prepare_where {
    my $self  = shift;
    my $dbh   = $self->_dbh();
    my $field = $self->_key_field;
    my @extra_id;
    my @docs;
    foreach (@_) {
        if ( defined $_->{id} ) {
            push @docs, $_->{id};
        }
        else {
            push @extra_id, $_;
        }

    }
    my @add_where;
    push @add_where, "$field in (" . join( "," => @docs ) . ")" if @docs;
    foreach my $exp (@extra_id) {
        my @and_where;
        while ( my ( $key, $val ) = each %$exp ) {
            my $vals = join ",",
              map { /^\d+$/ ? $_ : $dbh->quote($_) }
              ( ref($val) ? @$val : ($val) );
            if ( $key =~ s%([<>])%% ) {
                push @and_where, qq!$key $1 $vals!;
            }
            else {
                push @and_where, qq!$key in ($vals)!;
            }
        }
        push @add_where, " ( " . join( " and ", @and_where ) . " ) " if @and_where;
    }
    my $extr_where = join " or ", @add_where if @add_where;
    return $extr_where;
}

sub _fetch {
    my $self       = shift;
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $where      = $self->_prepare_where(@_);
    return {} unless $where;
    my $str    = "SELECT * FROM $table_name WHERE $where";
    my $result = {};
    my %keys_hash;
    my $qrt = $self->_query_dbh($str);

    while ( my $rec = $qrt->fetchrow_hashref ) {
        my %hash = %$rec;
        my $id   = $hash{$field};
        delete $hash{$field} if $self->_is_delete_key_field;
        $result->{$id} = $self->after_load( \%hash );
    }
    $qrt->finish;
    return $result;
}

sub _create {
    my ( $self, %arg ) = @_;
    my $table_name = $self->_table_name();
    my $id;
    my $field = $self->_key_field;
    if ( $self->_is_delete_key_field ) {
        $id = $arg{$field};
        delete $arg{$field};
    }
    my @keys = keys %arg;
    my $str = "INSERT INTO  $table_name (" . join( ",", @keys ) . ") VALUES ("
      . join( ",",
        map { $self->_dbh()->quote( defined($_) ? $_ : '' ) }
          map { $arg{$_} } @keys )
      . ")";
    $self->_query_dbh($str);
    my $inserted_id;
    if ( !$self->_is_delete_key_field && exists $arg{$field} ) {
        $inserted_id = $arg{$field};
    }
    else {
        $inserted_id =
             $self->_dbh->last_insert_id( '', '', $table_name, $field )
          || $self->GetLastID();
    }
    return { $inserted_id => $self->fetch_object($inserted_id) };
}

sub _delete {
    my $self       = shift;
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    return [] unless scalar @_;
    my $str =
      "DELETE FROM $table_name WHERE $field IN ("
      . join( ",", map { $_->{id} } @_ ) . ")";
    $self->_query_dbh($str);
    return \@_;
}

sub _fetch_ids {
    my $self       = shift;
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $query      = "SELECT $field FROM $table_name";
    return $dbh->selectcol_arrayref($query);
}

sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    my %hash;
    tie %hash, 'Objects::Collection::ActiveRecord', hash => $ref;
    if ( ref( $self->_sub_ref ) eq 'CODE' ) {
        return $self->_sub_ref()->( $key, \%hash );
    }
    return \%hash;
}

# overlap for support get by query
sub fetch_object {
    my $self = shift;
    my ($obj) = values %{ $self->fetch_objects(@_) };
    $obj;
}

sub GetLastID {
    my $self       = shift;
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $res        =
      $self->_query_dbh("select max($field)as res from $table_name")
      ->fetchrow_hashref;
    return $res->{res};
}

1;
__END__


=head1 SEE ALSO

Objects::Collection::ActiveRecord, Objects::Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


