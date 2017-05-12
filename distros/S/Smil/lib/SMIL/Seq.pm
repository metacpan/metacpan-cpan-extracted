package SMIL::Seq;

$VERSION = "0.898";

use SMIL::TimelineBase;
use SMIL::XMLContainer;

@ISA = qw( SMIL::XMLContainer ); 

sub init {
    my $self = shift;
    my %hash = @_;
    $self->SUPER::init( "seq" );
    
    my %attrs = $self->createValidAttributes( { %hash },
					      [@timelineAttributes] );
    $self->setAttributes( %attrs );
}
