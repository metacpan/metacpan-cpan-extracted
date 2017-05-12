package t::TestObj;

use strict;

use base qw( Tangence::Object );

use Tangence::Constants;

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = $class->SUPER::new( %args );

   for (qw( scalar array queue hash s_scalar )) {
      $self->${\"set_prop_$_"}( $args{$_} ) if defined $args{$_};
   }

   return $self;
}

sub describe
{
   my $self = shift;
   return (ref $self) . qq([scalar=) . $self->get_prop_scalar . q(]);
}

sub method_method
{
   my $self = shift;
   my ( $ctx, $i, $s ) = @_;
   return "$i/$s";
}

sub method_noreturn
{
   my $self = shift;
   return;
}

sub init_prop_scalar { 123 }
sub init_prop_hash   { { one => 1, two => 2, three => 3 } }
sub init_prop_queue  { [ 1, 2, 3 ] }
sub init_prop_array  { [ 1, 2, 3 ] }

sub add_number
{
   my $self = shift;
   my ( $name, $num ) = @_;

   if( index( my $scalar = $self->get_prop_scalar, $num ) == -1 ) {
      $scalar .= $num;
      $self->set_prop_scalar( $scalar );
   }

   $self->add_prop_hash( $name, $num );

   if( !grep { $_ == $num } @{ $self->get_prop_array } ) {
      $self->push_prop_array( $num );
   }
}

sub del_number
{
   my $self = shift;
   my ( $num ) = @_;

   my $hash = $self->get_prop_hash;
   my $name;
   $hash->{$_} == $num and ( $name = $_, last ) for keys %$hash;

   defined $name or die "No name for $num";

   if( index( ( my $scalar = $self->get_prop_scalar ), $num ) != -1 ) {
      $scalar =~ s/\Q$num//;
      $self->set_prop_scalar( $scalar );
   }

   $self->del_prop_hash( $name );

   my $array = $self->get_prop_array;
   if( grep { $_ == $num } @$array ) {
      my $index;
      $array->[$_] == $num and ( $index = $_, last ) for 0 .. $#$array;
      $index == 0 ? $self->shift_prop_array() : $self->splice_prop_array( $index, 1, () );
   }
}

1;
