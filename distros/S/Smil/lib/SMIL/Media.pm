package SMIL::Media;

$VERSION = "0.898";

use SMIL::XMLTag;
use SMIL::MediaResolver;
use SMIL::MediaAttributes;

#my @mediaAttributes = ( "begin", "end", "clip-end", "clip-begin", 
#		       "start", "fill", "src", "region", "id", "dur", "transition" );

@ISA = qw( SMIL::XMLTag SMIL::MediaResolver );

my $type = "type";
my $INLINE = 'inline';

sub init {
    my $self = shift;
    my %hash = @_;
    
    my $tag = $hash{ $type } and $hash{ $type } !~ /.\/./ ? 
	$hash{ $type } : "ref";
    $self->SUPER::init( $tag );
    
    if( $hash{ $INLINE } ) {
	print "Setting inline\n";
	$self->{_inline} = 1;
    }
    
    my %mediaAttrs = $self->createValidAttributes( { %hash }, 
						   [ @mediaAttributes ] );
    $self->setAttributes( %mediaAttrs );
    
    $self->setFavorite( "src" );
}

sub getAsString {
    
    my $self = shift;
    my $returnString = "";
    my $notInline = 0;
    
    print "Getting as string\n";
    
    if( !$self->{_inline} ) {
	$notInline = 1;
    }
    if( $self->{_inline} ) {
	eval 'use MIME::Base64';
	my $canEncode = !$@; 
	
	if( $canEncode ) {
	    # OK, download the media, or whatever and Base64 encode it.
	    my( $returnString, $type ) = $self->getContent;
	    
	    # encode it
	    $returnString = &encode_base64( $returnString );
	    
	    # tack on the type
	    $returnString = "data:$type;base64,$content";
	}
	else {
	    $notInline = 1;
	}
    }
    
    if( $notInline ) {
	$returnString = $self->SUPER::getAsString;
    }
    
    return $returnString;
    
}

