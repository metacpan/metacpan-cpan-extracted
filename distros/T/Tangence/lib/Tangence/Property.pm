#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Tangence::Property 0.33;

use warnings;
use base qw( Tangence::Meta::Property );

use Carp;

use Tangence::Constants;

require Tangence::Type;

use Struct::Dumb;
struct Instance => [qw( value callbacks cursors )];

=head1 NAME

C<Tangence::Property> - server implementation of a C<Tangence> property

=head1 DESCRIPTION

This module is a component of L<Tangence::Server>. It is not intended for
end-user use directly.

=cut

sub build_accessor
{
   my $prop = shift;
   my ( $subs ) = @_;

   my $pname = $prop->name;
   my $dim   = $prop->dimension;

   $subs->{"new_prop_$pname"} = sub {
      my $self = shift;

      my $initial;

      if( my $code = $self->can( "init_prop_$pname" ) ) {
         $initial = $code->( $self );
      }
      elsif( $dim == DIM_SCALAR ) {
         $initial = $prop->type->default_value;
      }
      elsif( $dim == DIM_HASH ) {
         $initial = {};
      }
      elsif( $dim == DIM_QUEUE or $dim == DIM_ARRAY ) {
         $initial = [];
      }
      elsif( $dim == DIM_OBJSET ) {
         $initial = {}; # these have hashes internally
      }
      else {
         croak "Unrecognised dimension $dim for property $pname";
      }

      $self->{properties}->{$pname} = Instance( $initial, [], [] );
   };

   $subs->{"get_prop_$pname"} = sub {
      my $self = shift;
      return $self->{properties}->{$pname}->value;
   };

   $subs->{"set_prop_$pname"} = sub {
      my $self = shift;
      my ( $newval ) = @_;
      $self->{properties}->{$pname}->value = $newval;
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_set}->( $self, $newval ) for @$cbs;
   };

   my $dimname = DIMNAMES->[$dim];
   if( my $code = __PACKAGE__->can( "_accessor_for_$dimname" ) ) {
      $code->( $prop, $subs, $pname );
   }
   else {
      croak "Unrecognised property dimension $dim for $pname";
   }
}

sub _accessor_for_scalar
{
   # Nothing needed
}

sub _accessor_for_hash
{
   my $prop = shift;
   my ( $subs, $pname ) = @_;

   $subs->{"add_prop_$pname"} = sub {
      my $self = shift;
      my ( $key, $value ) = @_;
      $self->{properties}->{$pname}->value->{$key} = $value;
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value )
                       : $_->{on_add}->( $self, $key, $value ) for @$cbs;
   };

   $subs->{"del_prop_$pname"} = sub {
      my $self = shift;
      my ( $key ) = @_;
      delete $self->{properties}->{$pname}->value->{$key};
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_del}->( $self, $key ) for @$cbs;
   };
}

sub _accessor_for_queue
{
   my $prop = shift;
   my ( $subs, $pname ) = @_;

   $subs->{"push_prop_$pname"} = sub {
      my $self = shift;
      my @values = @_;
      push @{ $self->{properties}->{$pname}->value }, @values;
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_push}->( $self, @values ) for @$cbs;
   };

   $subs->{"shift_prop_$pname"} = sub {
      my $self = shift;
      my ( $count ) = @_;
      $count = 1 unless @_;
      splice @{ $self->{properties}->{$pname}->value }, 0, $count, ();
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_shift}->( $self, $count ) for @$cbs;
      my $cursors = $self->{properties}->{$pname}->cursors;
      $_->idx -= $count for @$cursors;
   };

   $subs->{"cursor_prop_$pname"} = sub {
      my $self = shift;
      my ( $from ) = @_;
      my $idx = $from == CUSR_FIRST ? 0 :
                $from == CUSR_LAST  ? scalar @{ $self->{properties}->{$pname}->value } :
                                      die "Unrecognised from";
      my $cursors = $self->{properties}->{$pname}->cursors ||= [];
      push @$cursors, my $cursor = Tangence::Property::_Cursor->new( $self->{properties}->{$pname}->value, $prop, $idx );
      return $cursor;
   };

   $subs->{"uncursor_prop_$pname"} = sub {
      my $self = shift;
      my ( $cursor ) = @_;
      my $cursors = $self->{properties}->{$pname}->cursors or return;
      @$cursors = grep { $_ != $cursor } @$cursors;
   };
}

sub _accessor_for_array
{
   my $prop = shift;
   my ( $subs, $pname ) = @_;

   $subs->{"push_prop_$pname"} = sub {
      my $self = shift;
      my @values = @_;
      push @{ $self->{properties}->{$pname}->value }, @values;
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_push}->( $self, @values ) for @$cbs;
   };

   $subs->{"shift_prop_$pname"} = sub {
      my $self = shift;
      my ( $count ) = @_;
      $count = 1 unless @_;
      splice @{ $self->{properties}->{$pname}->value }, 0, $count, ();
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_shift}->( $self, $count ) for @$cbs;
   };

   $subs->{"splice_prop_$pname"} = sub {
      my $self = shift;
      my ( $index, $count, @values ) = @_;
      splice @{ $self->{properties}->{$pname}->value }, $index, $count, @values;
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_splice}->( $self, $index, $count, @values ) for @$cbs;
   };

   $subs->{"move_prop_$pname"} = sub {
      my $self = shift;
      my ( $index, $delta ) = @_;
      return if $delta == 0;
      # it turns out that exchanging neighbours is quicker by list assignment,
      # but other times it's generally best to use splice() to extract then
      # insert
      my $cache = $self->{properties}->{$pname}->value;
      if( abs($delta) == 1 ) {
         @{$cache}[$index,$index+$delta] = @{$cache}[$index+$delta,$index];
      }
      else {
         my $elem = splice @$cache, $index, 1, ();
         splice @$cache, $index + $delta, 0, ( $elem );
      }
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_move}->( $self, $index, $delta ) for @$cbs;
   };
}

sub _accessor_for_objset
{
   my $prop = shift;
   my ( $subs, $pname ) = @_;

   # Different get and set methods
   $subs->{"get_prop_$pname"} = sub {
      my $self = shift;
      return [ values %{ $self->{properties}->{$pname}->value } ];
   };

   $subs->{"set_prop_$pname"} = sub {
      my $self = shift;
      my ( $newval ) = @_;
      $self->{properties}->{$pname}->value = $newval;
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_set}->( $self, [ values %$newval ] ) for @$cbs;
   };

   $subs->{"add_prop_$pname"} = sub {
      my $self = shift;
      my ( $obj ) = @_;
      $self->{properties}->{$pname}->value->{$obj->id} = $obj;
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_add}->( $self, $obj ) for @$cbs;
   };

   $subs->{"del_prop_$pname"} = sub {
      my $self = shift;
      my ( $obj_or_id ) = @_;
      my $id = ref $obj_or_id ? $obj_or_id->id : $obj_or_id;
      delete $self->{properties}->{$pname}->value->{$id};
      my $cbs = $self->{properties}->{$pname}->callbacks;
      $_->{on_updated} ? $_->{on_updated}->( $self, $self->{properties}->{$pname}->value ) 
                       : $_->{on_del}->( $self, $id ) for @$cbs;
   };
}

sub make_type
{
   shift;
   return Tangence::Type->make( @_ );
}

class # hide from CPAN
   Tangence::Property::_Cursor
{
   use Carp;

   use Tangence::Constants;

   field $queue :param :reader;
   field $prop  :param :reader;
   field $idx   :param :mutator;

   sub BUILDARGS ( $class, $queue, $prop, $idx )
   {
      return ( queue => $queue, prop => $prop, idx => $idx );
   }

   method handle_request_CUSR_NEXT
   {
      my ( $ctx, $message ) = @_;

      my $direction = $message->unpack_int();
      my $count     = $message->unpack_int();

      my $start_idx = $idx;

      if( $direction == CUSR_FWD ) {
         $count = scalar @$queue - $idx if $count > scalar @$queue - $idx;

         $idx += $count;
      }
      elsif( $direction == CUSR_BACK ) {
         $count = $idx if $count > $idx;
         $idx -= $count;
         $start_idx = $idx;
      }
      else {
         return $ctx->responderr( "Unrecognised cursor direction $direction" );
      }

      my @result = @{$queue}[$start_idx .. $start_idx + $count - 1];

      $ctx->respond( Tangence::Message->new( $ctx->stream, MSG_CUSR_RESULT )
         ->pack_int( $start_idx )
         ->pack_all_sametype( $prop->type, @result )
      );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
