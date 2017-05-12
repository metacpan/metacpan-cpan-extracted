package SMIL::Href;

$VERSION = "0.898";

use SMIL::UnanchoredMedia;
use SMIL::SystemSwitches;

@ISA = ( SMIL::XMLContainer );

my @validHrefAttrs = ( 'href' );
my $media = 'media';

sub init {
    my $self = shift;
    my %hash = @_;
    $self->SUPER::init( "a" );

    my %attrs = $self->createValidAttributes( { %hash },
					     [@validHrefAttrs
					#, @systemSwitchAttributes 
					] );
    $self->setAttributes( %attrs );

    my $ref = new SMIL::UnanchoredMedia( %hash );
    $self->setTagContents( $media => $ref );
}
