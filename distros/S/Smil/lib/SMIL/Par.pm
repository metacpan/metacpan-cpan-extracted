package SMIL::Par;

$VERSION = "0.898";

use Carp;
use SMIL::TimelineBase;
use SMIL::SystemSwitches;
use SMIL::XMLContainer;

@ISA = qw( SMIL::XMLContainer ); 

sub init {
    my $self = shift;
    my %hash = @_;
    $self->SUPER::init( "par" );

    my %attrs = $self->createValidAttributes( { %hash },
					     [@timelineAttributes, 
					      @systemSwitchAttributes] );

    $self->setAttributes( %attrs );

}
