package SMIL::Switch;

$VERSION = "0.898";

use SMIL::MediaFactory;
@ISA = qw( SMIL::XMLContainer );

my $item_index = "item_index";
my $switch = 'switch';

sub init {
    my $self = shift;
    $self->SUPER::init( "switch" );

    my $switch_param = shift;
    my $medias = shift;
    
    foreach $item ( @$medias ) {
	# Check to see what this is, if it is a HASH then
	# add it like this, otherwise trust the user
	my $type = ref( $item );
	if( ref( $item ) =~ /HASH/ ) {
	    $self->setTagContents( $self->{$item_index}++ => 
				   getMediaObject( %$item, 
						   $switch => 
						   $switch_param ));
	}
	else {
            $self->setTagContents( $self->{$item_index}++ => $item );
	}
    }
}
