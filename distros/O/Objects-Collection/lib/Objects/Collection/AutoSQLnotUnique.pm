package Objects::Collection::AutoSQLnotUnique;


=head1 NAME

 Objects::Collection::AutoSQLnotUnique - class for collections of data, stored in database.

=head1 SYNOPSIS

  use Objects::Collection::AutoSQL;
  my $metaobj = new Objects::Collection::AutoSQL::
      dbh => $dbh,         #database connect
      table => 'metadata', #table name
      field=> 'mid',       #key field (IDs)
      cut_key =>1,         #delete field mid from readed records, 
                           #or delete_key=>1
      sub_ref =>
              #callback for create objects for readed records
              sub { my $id = shift; new MyObject:: shift }
             
=head1 DESCRIPTION

Provide simply access to records, with not unique key field.

=cut

use Objects::Collection::AutoSQL;
use Data::Dumper;
use Carp;
use strict;
use warnings;

our @ISA = qw(Objects::Collection::AutoSQL);
our $VERSION = '0.01';

#overwrite this method !
sub after_load {
    my $self = shift;
    return $_[0]
}

#overwrite this method !
sub before_save {
    my $self = shift;
    return $_[0]
}

sub _fetch {
  my $self       = shift;
  my $dbh        = $self->_dbh;
  my $table_name = $self->_table_name();
  my $field      = $self->_key_field;
  my @extra_id;
  my @docs;
  foreach (@_) {
     if ( $_->{id} ) {
         push @docs, $_->{id};
      }
      else {
          push @extra_id, $_;
      }
  }
  my @add_where;
  if (  
        @extra_id 
            and 
        my $ext_where = $self->_prepare_where(@extra_id)
     ) {
     push @docs, @{ $self->get_ids_where($ext_where) };
     return $self->_fetch(map { { id=>$_ } } @docs)
  } else {
    return {} unless @docs;
    my $where = $self->_prepare_where(map {{id=>$_}} @docs);
    my $str ="SELECT * FROM $table_name WHERE $where";
    my $result = {};
    my %keys_hash;
    my $qrt = $self->_query_dbh($str);
    while ( my $rec = $qrt->fetchrow_hashref ) {
        my %hash = %$rec;
        my $id = $hash{$field};
        delete $hash{$field} if $self->_is_delete_key_field;
        push @{ $result->{$id} }, \%hash;
    }
    $qrt->finish;
    #prepare result records
    while ( my ($key, $val) = each %$result ) {
      my $val = $result->{$key};
      $result->{$key} = $self->after_load(ref $val ? @$val : $val);
    }
    return { map { $_ => $result->{$_}||{} } ( keys %$result, @docs ) };
  }
}

#=head1 _create - create record

#use:
# $obj->create(234=>{attr1=>1,attr2=>'value'},)

#=cut

sub _create {
    my $self = shift;
    my %args = @_;
    return {} unless %args;
    my $coll_ref = $self->_obj_cache();
    my %created;
    while ( my ($id, $attr_hash_ref) = each %args ) {
        next if exists $coll_ref->{$id};
        my $res = $self->_prepare_record($id,$attr_hash_ref);
        $coll_ref->{$id} = $res;
        $created{$id}++
    }
    return \%created
}

sub _store {
    my ( $self, $ref ) = @_;
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my @id2del = keys %$ref;
    $self->_query_dbh("DELETE FROM $table_name where $field in (".(join ','=>@id2del).")");
    my $sth;
    my @fields;
    while ( my ( $key, $rec_ref ) = each %$ref ) {
        my $tmp_val = ref($rec_ref) eq 'HASH' ? $rec_ref : $rec_ref->_get_attr;
        my $prepared = $self->before_save($tmp_val);
        my @rows = ref($prepared) eq 'ARRAY' ? @$prepared : ($prepared);
        foreach my $val ( @rows ) {
        $val->{$field} = $key;
        unless ( @fields ) { 
            @fields = keys %$val;
            };
        my $exex_opt = join ",",  map { '?' } (@fields);
        $sth = $dbh->prepare("INSERT INTO $table_name ( ".join(',',@fields).") VALUES ( $exex_opt )") unless $sth;
        $sth->execute(@$val{ @fields });
        }
   }
}

1;

__END__


=head1 SEE ALSO

Objects::Collection::AutoSQL, Objects::Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

