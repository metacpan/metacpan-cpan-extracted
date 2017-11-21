#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2014 -- leonerd@leonerd.org.uk

package Tangence::Message;

use strict;
use warnings;

# Currently depends on atleast Perl 5.10.0 to provide the > format modifier
# for pack, to specify big-endian integers. If this code can be modified, this
# restriction could be listed.
use 5.010; # pack endian formats

our $VERSION = '0.24';

use Carp;

use Tangence::Constants;

use Tangence::Class;
use Tangence::Meta::Method;
use Tangence::Meta::Event;
use Tangence::Property;
use Tangence::Meta::Argument;
use Tangence::Struct;
use Tangence::Types;

use Tangence::Object;

use List::Util 1.29 qw( pairmap );
use Scalar::Util qw( weaken blessed );

# Normally we don't care about hash key order. But, when writing test scripts
# that will assert on the serialisation bytes, we do. Setting this to some
# true value will sort keys first
our $SORT_HASH_KEYS = 0;

sub new
{
   my $class = shift;
   my ( $stream, $code, $record ) = @_;

   $record = "" unless defined $record;

   return bless {
      stream => $stream,
      code   => $code,
      record => $record,
   }, $class;
}

sub try_new_from_bytes
{
   my $class = shift;
   my $stream = shift;

   return undef unless length $_[0] >= 5;

   my ( $code, $len ) = unpack( "CN", $_[0] );
   return 0 unless length $_[0] >= 5 + $len;

   substr( $_[0], 0, 5, "" );

   my $record = substr( $_[0], 0, $len, "" );

   return $class->new( $stream, $code, $record );
}

sub stream
{
   my $self = shift;
   return $self->{stream};
}

sub code
{
   my $self = shift;
   return $self->{code};
}

sub bytes
{
   my $self = shift;

   my $record = $self->{record};
   return pack( "CNa*", $self->{code}, length($record), $record );
}

sub _pack_leader
{
   my $self = shift;
   my ( $type, $num ) = @_;

   if( $num < 0x1f ) {
      $self->{record} .= pack( "C", ( $type << 5 ) | $num );
   }
   elsif( $num < 0x80 ) {
      $self->{record} .= pack( "CC", ( $type << 5 ) | 0x1f, $num );
   }
   else {
      $self->{record} .= pack( "CN", ( $type << 5 ) | 0x1f, $num | 0x80000000 );
   }
}

sub _peek_leader_type
{
   my $self = shift;

   while(1) {
      length $self->{record} or croak "Ran out of bytes before finding a leader";

      my ( $typenum ) = unpack( "C", $self->{record} );
      my $type = $typenum >> 5;

      return $type unless $type == DATA_META;

      substr( $self->{record}, 0, 1, "" );

      my $num  = $typenum & 0x1f;
      if( $num == DATAMETA_CONSTRUCT ) {
         $self->unpackmeta_construct;
      }
      elsif( $num == DATAMETA_CLASS ) {
         $self->unpackmeta_class;
      }
      elsif( $num == DATAMETA_STRUCT ) {
         $self->unpackmeta_struct;
      }
      else {
         die sprintf("TODO: Data stream meta-operation 0x%02x", $num);
      }
   }
}

sub _unpack_leader
{
   my $self = shift;
   my ( $peek ) = @_;

   my $type = $self->_peek_leader_type;
   my ( $typenum ) = unpack( "C", $self->{record} );

   my $num  = $typenum & 0x1f;

   my $len = 1;
   if( $num == 0x1f ) {
      ( $num ) = unpack( "x C", $self->{record} );

      if( $num < 0x80 ) {
         $len = 2;
      }
      else {
         ( $num ) = unpack( "x N", $self->{record} );
         $num &= 0x7fffffff;
         $len = 5;
      }
   }

   substr( $self->{record}, 0, $len ) = "" if !$peek;

   return $type, $num;
}

sub _pack
{
   my $self = shift;
   $self->{record} .= $_[0];
}

sub _unpack
{
   my $self = shift;
   my ( $num ) = @_;
   length $self->{record} >= $num or croak "Can't pull $num bytes as there aren't enough";
   return substr( $self->{record}, 0, $num, "" );
}

sub pack_bool
{
   my $self = shift;
   my ( $d ) = @_;
   TYPE_BOOL->pack_value( $self, $d );
   return $self;
}

sub unpack_bool
{
   my $self = shift;
   return TYPE_BOOL->unpack_value( $self );
}

sub pack_int
{
   my $self = shift;
   my ( $d ) = @_;
   TYPE_INT->pack_value( $self, $d );
   return $self;
}

sub unpack_int
{
   my $self = shift;
   return TYPE_INT->unpack_value( $self );
}

sub pack_str
{
   my $self = shift;
   my ( $d ) = @_;
   TYPE_STR->pack_value( $self, $d );
   return $self;
}

sub unpack_str
{
   my $self = shift;
   return TYPE_STR->unpack_value( $self );
}

sub pack_record
{
   my $self = shift;
   my ( $rec, $struct ) = @_;

   my $stream = $self->{stream};

   $struct ||= eval { Tangence::Struct->for_perlname( ref $rec ) } or
      croak "No struct for " . ref $rec;

   $self->packmeta_struct( $struct ) unless $stream->peer_hasstruct->{$struct->perlname};

   my @fields = $struct->fields;
   $self->_pack_leader( DATA_RECORD, scalar @fields );
   $self->pack_int( $stream->peer_hasstruct->{$struct->perlname}->[1] );
   foreach my $field ( @fields ) {
      my $fieldname = $field->name;
      $field->type->pack_value( $self, $rec->$fieldname );
   }

   return $self;
}

sub unpack_record
{
   my $self = shift;
   my ( $struct ) = @_;

   my $stream = $self->{stream};

   my ( $type, $num ) = $self->_unpack_leader();
   $type == DATA_RECORD or croak "Expected to unpack a record but did not find one";

   my $structid = $self->unpack_int();
   my $got_struct = $stream->message_state->{id2struct}{$structid};
   if( !$struct ) {
      $struct = $got_struct;
   }
   else {
      $struct->name eq $got_struct->name or
         croak "Expected to unpack a ".$struct->name." but found ".$got_struct->name;
   }

   $num == $struct->fields or croak "Expected ".$struct->name." to unpack from ".(scalar $struct->fields)." fields";

   my %values;
   foreach my $field ( $struct->fields ) {
      $values{$field->name} = $field->type->unpack_value( $self );
   }

   return $struct->perlname->new( %values );
}

sub packmeta_construct
{
   my $self = shift;
   my ( $obj ) = @_;

   my $stream = $self->{stream};

   my $class = $obj->class;
   my $id    = $obj->id;

   $self->packmeta_class( $class ) unless $stream->peer_hasclass->{$class->perlname};

   my $smashkeys = $class->smashkeys;

   $self->_pack_leader( DATA_META, DATAMETA_CONSTRUCT );
   $self->pack_int( $id );
   $self->pack_int( $stream->peer_hasclass->{$class->perlname}->[2] );

   if( @$smashkeys ) {
      my $smashdata = $obj->smash( $smashkeys );

      for my $prop ( @$smashkeys ) {
         $stream->_install_watch( $obj, $prop );
      }

      if( $stream->_ver_can_typed_smash ) {
         $self->_pack_leader( DATA_LIST, scalar @$smashkeys );
         foreach my $prop ( @$smashkeys ) {
            $class->property( $prop )->overall_type->pack_value( $self, $smashdata->{$prop} );
         }
      }
      else {
         TYPE_LIST_ANY->pack_value( $self, [ map { $smashdata->{$_} } @$smashkeys ] );
      }
   }
   else {
      $self->_pack_leader( DATA_LIST, 0 );
   }

   weaken( my $weakstream = $stream );
   $stream->peer_hasobj->{$id} = $obj->subscribe_event( 
      destroy => sub { $weakstream->object_destroyed( @_ ) if $weakstream },
   );
}

sub unpackmeta_construct
{
   my $self = shift;

   my $stream = $self->{stream};

   my $id = $self->unpack_int();
   my $classid = $self->unpack_int();
   my $class_perlname = $stream->message_state->{id2class}{$classid};

   my ( $class, $smashkeys ) = @{ $stream->peer_hasclass->{$class_perlname} };

   my $smasharr;
   if( $stream->_ver_can_typed_smash ) {
      my ( $type, $num ) = $self->_unpack_leader;
      $type == DATA_LIST or croak "Expected to unpack a LIST of smashed data";
      $num == @$smashkeys or croak "Expected to unpack a LIST of " . ( scalar @$smashkeys ) . " elements";

      foreach my $prop ( @$smashkeys ) {
         push @$smasharr, $class->property( $prop )->overall_type->unpack_value( $self );
      }
   }
   else {
      $smasharr = TYPE_LIST_ANY->unpack_value( $self );
   }

   my $smashdata;
   $smashdata->{$smashkeys->[$_]} = $smasharr->[$_] for 0 .. $#$smasharr;

   $stream->make_proxy( $id, $class_perlname, $smashdata );
}

sub packmeta_class
{
   my $self = shift;
   my ( $class ) = @_;

   my $stream = $self->{stream};

   my @superclasses = grep { $_->name ne "Tangence.Object" } $class->direct_superclasses;

   $stream->peer_hasclass->{$_->perlname} or $self->packmeta_class( $_ ) for @superclasses;

   $self->_pack_leader( DATA_META, DATAMETA_CLASS );

   my $smashkeys = $class->smashkeys;

   my $classid = ++$stream->message_state->{next_classid};

   $self->pack_str( $class->name );
   $self->pack_int( $classid );
   my $classrec = Tangence::Struct::Class->new(
      methods => {
         pairmap {
            $a => Tangence::Struct::Method->new(
               arguments => [ map { $_->type->sig } $b->arguments ],
               returns   => ( $b->ret ? $b->ret->sig : "" ),
            )
         } %{ $class->direct_methods }
      },
      events => {
         pairmap {
            $a => Tangence::Struct::Event->new(
               arguments => [ map { $_->type->sig } $b->arguments ],
            )
         } %{ $class->direct_events }
      },
      properties => {
         pairmap {
            $a => Tangence::Struct::Property->new(
               dimension => $b->dimension,
               type      => $b->type->sig,
               smashed   => $b->smashed,
            )
         } %{ $class->direct_properties }
      },
      superclasses => [ map { $_->name } @superclasses ],
   );
   $self->pack_record( $classrec );

   TYPE_LIST_STR->pack_value( $self, $smashkeys );

   $stream->peer_hasclass->{$class->perlname} = [ $class, $smashkeys, $classid ];
}

sub unpackmeta_class
{
   my $self = shift;

   my $stream = $self->{stream};

   my $name = $self->unpack_str();
   my $classid = $self->unpack_int();
   my $classrec = $self->unpack_record();

   my $class = Tangence::Meta::Class->new( name => $name );
   $class->define(
      methods => { 
         pairmap {
            $a => Tangence::Meta::Method->new(
               class     => $class,
               name      => $a,
               ret       => $b->returns ? Tangence::Type->new_from_sig( $b->returns )
                                        : undef,
               arguments => [ map {
                  Tangence::Meta::Argument->new(
                     type => Tangence::Type->new_from_sig( $_ ),
                  )
               } @{ $b->arguments } ],
            )
         } %{ $classrec->methods }
      },

      events => {
         pairmap {
            $a => Tangence::Meta::Event->new(
               class     => $class,
               name      => $a,
               arguments => [ map {
                  Tangence::Meta::Argument->new(
                     type => Tangence::Type->new_from_sig( $_ ),
                  )
               } @{ $b->arguments } ],
            )
         } %{ $classrec->events }
      },

      properties => {
         pairmap {
            # Need to use non-Meta:: Property so it can generate overall type
            # using Tangence::Type instead of Tangence::Meta::Type
            $a => Tangence::Property->new(
               class     => $class,
               name      => $a,
               dimension => $b->dimension,
               type      => Tangence::Type->new_from_sig( $b->type ),
               smashed   => $b->smashed,
            )
         } %{ $classrec->properties }
      },

      superclasses => do {
         my @superclasses = map {
            ( my $perlname = $_ ) =~ s/\./::/g;
            $stream->peer_hasclass->{$perlname}->[3] or croak "Unrecognised class $perlname";
         } @{ $classrec->superclasses };

         @superclasses ? \@superclasses : [ Tangence::Class->for_name( "Tangence.Object" ) ]
      },
   );

   my $perlname = $class->perlname;

   my $smashkeys = TYPE_LIST_STR->unpack_value( $self );

   $stream->peer_hasclass->{$perlname} = [ $class, $smashkeys, $classid, $class ];
   if( defined $classid ) {
      $stream->message_state->{id2class}{$classid} = $perlname;
   }
}

sub packmeta_struct
{
   my $self = shift;
   my ( $struct ) = @_;

   my $stream = $self->{stream};

   $self->_pack_leader( DATA_META, DATAMETA_STRUCT );

   my @fields = $struct->fields;

   my $structid = ++$stream->message_state->{next_structid};
   $self->pack_str( $struct->name );
   $self->pack_int( $structid );
   TYPE_LIST_STR->pack_value( $self, [ map { $_->name } @fields ] );
   TYPE_LIST_STR->pack_value( $self, [ map { $_->type->sig } @fields ] );

   $stream->peer_hasstruct->{$struct->perlname} = [ $struct, $structid ];
}

sub unpackmeta_struct
{
   my $self = shift;

   my $stream = $self->{stream};

   my $name     = $self->unpack_str();
   my $structid = $self->unpack_int();
   my $names    = TYPE_LIST_STR->unpack_value( $self );
   my $types    = TYPE_LIST_STR->unpack_value( $self );

   my $struct = Tangence::Struct->new( name => $name );
   if( !$struct->defined ) {
      $struct->define(
         fields => [
            map { $names->[$_] => $types->[$_] } 0 .. $#$names
         ]
      );
   }

   $stream->peer_hasstruct->{$struct->perlname} = [ $struct, $structid ];
   $stream->message_state->{id2struct}{$structid} = $struct;
}

sub pack_all_sametype
{
   my $self = shift;
   my $type = shift;

   $type->pack_value( $self, $_ ) for @_;

   return $self;
}

sub unpack_all_sametype
{
   my $self = shift;
   my ( $type ) = @_;
   my @data;
   push @data, $type->unpack_value( $self ) while length $self->{record};

   return @data;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
