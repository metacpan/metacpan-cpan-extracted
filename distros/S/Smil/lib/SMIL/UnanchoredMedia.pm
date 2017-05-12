package SMIL::UnanchoredMedia;

$VERSION = "0.898";

use SMIL::XMLTag;
use SMIL::MediaAttributes;
use SMIL::MediaResolver;

@ISA = qw( SMIL::XMLTag SMIL::MediaResolver );

my $media_type = 'type';
my $INLINE = 'inline';

sub init {
    my $self = shift;
    my %hash = @_;
    
    my $type = "";
				$type = $hash{ $media_type } 
				unless ( !$hash{ $media_type } or 
													$hash{ $media_type } =~ /.\/./ );
    $self->SUPER::init( $type ? $type : "ref" );
				
    if( $hash{ $INLINE } ) {
        $self->{_inline} = 1;
    }
				
    my %attrs = $self->createValidAttributes( { %hash },
					     [@mediaAttributes] );
    
    $self->setAttributes( %attrs );
    $self->setFavorite( "src" );
}

sub getAsString {
				
				my $self = shift;
				my $content =  "";
				
				if( $self->{_inline} ) {
								eval 'use MIME::Base64';
								my $canEncode = !$@; 
								
								if( $canEncode ) {
												# OK, download the media, or whatever and Base64 encode it.
												my( $content, $type ) = $self->getContent;
												
												# encode it
												$content = &encode_base64( $content );
												chomp $content;
												
												if( $content ) {
																# tack on the type
																$content = "data:$type;base64,$content";
																
																$self->setAttribute( "src" => $content );
												}
								}
				}
				
				return $self->SUPER::getAsString;
}

1;
