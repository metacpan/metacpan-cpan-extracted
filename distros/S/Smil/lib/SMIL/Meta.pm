package SMIL::Meta;

$VERSION = "0.898";

use SMIL::XMLTag;

@ISA = qw( SMIL::XMLTag );

my @validMetaAttrs = ( 'name', 'content' );

sub init {
    my $self = shift;
    $self->SUPER::init( "meta" );
    
    my $name = shift;
    my $content = shift;

    $self->setAttributes( 'name' => $name,
			 'content' => $content );
}

