package t::Ball;

use strict;

use base qw( Tangence::Object t::Colourable );

use Tangence::Constants;

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->set_prop_colour( $args{colour} );
   $self->set_prop_size( $args{size} );

   return $self;
}

sub describe
{
   my $self = shift;
   return (ref $self) . qq([colour=") . $self->get_prop_colour . q("]);
}

our $last_bounce_ctx;

sub method_bounce
{
   my $self = shift;
   my ( $ctx, $howhigh ) = @_;
   $last_bounce_ctx = $ctx;
   $self->fire_event( "bounced", $howhigh );
   return "bouncing";
}

1;
