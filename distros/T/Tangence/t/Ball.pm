package t::Ball;

use v5.26;
use warnings;
use experimental 'signatures';

use base qw( Tangence::Object t::Colourable );

use Tangence::Constants;

sub new ( $class, %args )
{
   my $self = $class->SUPER::new( %args );

   $self->set_prop_colour( $args{colour} ) if defined $args{colour};
   $self->set_prop_size( $args{size} ) if defined $args{size};

   return $self;
}

sub describe
{
   my $self = shift;
   return (ref $self) . qq([colour=") . $self->get_prop_colour . q("]);
}

our $last_bounce_ctx;

sub method_bounce ( $self, $ctx, $howhigh )
{
   $last_bounce_ctx = $ctx;
   $self->fire_event( "bounced", $howhigh );
   return "bouncing";
}

1;
