package SMIL::Transition;
$VERSION = "0.898";
use SMIL::XMLTag;
@ISA = qw( SMIL::XMLTag );

my @validAttrs = ( 'id', 'type', 'subtype', 'borderColor', 'borderWidth', 
																			'direction', 'dur', 'endProgress', 'fadeColor', 
																			'horzRepeat', 'startProgress', 'vertRepeat' );

sub init {
    my $self = shift;
    $self->SUPER::init( "transition" );
    $self->setAttributes( @_ );
}

1;
