package Smil;

$VERSION = "0.898";

use Carp;
use SMIL::XMLBase;
use SMIL::XMLContainer;
use SMIL::XMLTag;
use SMIL::Head;
use SMIL::Body;

my $TRUE = 'true';

@ISA = qw( SMIL::XMLContainer );

my $head = "head";
my $body = "body";
my @timelineStack;
my $smil;
my $file = "file";
my $INLINE = 'inline';

my $CV_SYSTEM_COMPONENT = "cv:systemComponent";
my @RP_SYSTEM_REQUIRED_ATTRIBUTE = ( "system-required" => "cv" );

my $RN_EXTENSIONS = 'rn-extensions';
my $RN_SHORT = 'rn';
my $QT_EXTENSIONS = 'qt-extensions';
my $QT_SHORT = 'qt';
my $QT_NS_URL = "http://www.apple.com/quicktime/resources/smilextensions";
my $QT_NS = "xmlns:qt";

my $SMIL_2_NS = 'xmlns';
my $SMIL_2_NS_URL = 'http://www.w3.org/2001/SMIL20/Language';

my $RN_SMIL_2_NAMESPACE = 'rnSmil2';
my $RN_SMIL_2_NS_URL = "http://features.real.com/2001/SMIL20/Extensions";
my $RN_SMIL_2_NS = "xmlns:$RN_SMIL_2_NAMESPACE";

my $VERSION_COMPATIBLE = 'version';
my $PLAYER_COMPATIBLE = 'player';
my $RP_COMPATIBLE = 'rp';
my $QT_COMPATIBLE = 'qt';

my $QT_AUTOPLAY = "qt:autoplay";
my $QT_CHAPTER_MODE = "qt:chapter-mode";
my $QT_IMMEDIATE_INSTANTIATION = "qt:immediate-instantiation";
my $QT_NEXT = "qt:next";
my $QT_TIME_SLIDER = "qt:time-slider";

my $RN_NS = "xmlns:cv";
my $RN_NS_URL = "http://features.real.com/systemComponent";

my %earliestAttribute = ( 'inline' => 7 );

my @RP_VERSION_MAPPING = ( "",  		# 0
																													"", 		# 1, unsupported
																													"", 		# 2, unsupported
																													"", 		# 3, unsupported
																													"", 		# 4, unsupported
																													"", 		# 5, unsupported
																													"", 		# 6, no switch allowed
																													
																													# 7, Gold Player 7
																													"http://features.real.com/?component;player=6.0.7.380", 		
																													
																													# 8, Gold Player 8
																													"http://features.real.com/?component;player=6.0.9.450",
																													);

my %VERSION_MAPPING = ( $RP_COMPATIBLE => \@RP_VERSION_MAPPING );

my %RP_FEATURE_VERSION_MAPPING = ( 'inline' => 7, 'newwindow' => 7 );

my %FEATURE_VERSION_MAPPING = ( $RP_COMPATIBLE => \%RP_FEATURE_VERSION_MAPPING );

my @smilAttributes = ( $RN_NS,
																							$QT_AUTOPLAY,
																							$QT_CHAPTER_MODE,
																							$QT_IMMEDIATE_INSTANTIATION,
																							$QT_NEXT,
																							$QT_TIME_SLIDER );

my @smil2Extensions = ( 'syncBehavior' );
my @rnSmil2Extensions = ( 'backgroundOpacity', 'bgcolor', 'chromaKey', 
																										'chromaKeyOpacity', 'chromaKeyTolerance', 'mediaOpacity' );


sub init {
    my $self = shift;
    $self->SUPER::init( "smil" );
				
    my %hash = @_;
    my %smilAttrs = $self->createValidAttributes( { %hash },
																																																		[ @smilAttributes ] );
				
    if( $hash{ $QT_SHORT } or 
								$hash{ $QT_EXTENSIONS } ) {
								$self->useQtExtensions;
    }
				
    if( $hash{ $RN_EXTENSIONS } or 
								$hash{ $RN_SHORT } ) {
								$self->useRnExtensions;	
    }
				
    $self->setAttributes( %smilAttrs );
    
    $self->setFavorite( $favorite ) if $favorite;
    $self->initHead( @_ );
    $self->initBody( @_ );
    $self->initFile( @_ );
}

sub setQtAutoplay {
				my $self = shift;
				$self->setAttribute( $QT_AUTOPLAY => $TRUE );
				$self->useQtExtensions;
}

sub setQtChapterMode {
				my $self = shift;
				my $dur = shift;
				$self->setAttribute( $QT_CHAPTER_MODE => $dur );
				$self->useQtExtensions;
}

sub useQtImmediateInstantiation {
				my $self = shift;
				$self->setAttribute( $QT_IMMEDIATE_INSTANTIATION => $TRUE );
				$self->useQtExtensions;
}

sub setQtNextPresentation {
				$self = shift;
				$next = shift;
				$self->setAttribute( $QT_NEXT => $next );
				$self->useQtExtensions;
}

sub useQtTimeSlider {
				$self = shift;
				$self->setAttribute( $QT_TIME_SLIDER => $TRUE );
				$self->useQtExtensions;
}

sub useRnExtensions {
				my $self = shift;
				my $version = shift;
				
				$self->setAttribute( $RN_NS => $RN_NS_URL );
				$self->setFavorite( $RN_NS );
}

sub useQtExtensions {
				my $self = shift;
				$self->setAttribute( $QT_NS => $QT_NS_URL );
				$self->setFavorite( $QT_NS );
}

sub getRootHeight {
    my $self = shift;
    my $hd = $self->getContentObjectByName( $head );
    return $hd ? $hd->getRootHeight() : 0;
}

sub getRootWidth {
    my $self = shift;
    my $hd = $self->getContentObjectByName( $head );
    return $hd ? $hd->getRootWidth() : 0;
}

sub getAsString {
    my $self = shift;

#    croak "Need to make sure to match start with end when defining timeline"
#	if( $check_errors && @{$self->{$timelineStack}} );

    return $self->SUPER::getAsString();
}

sub initFile {
    my $self = shift;
    my %hash = @_;
    if( $hash{ $file } ) {
								$self->{$file} = $hash{ $file };
    }
}

sub initHead {
    my $self = shift;
    my %hash = @_;
    $self->setTagContents( $head => new SMIL::Head( @_ ) )
								if( ( $hash{ 'height' } && $hash{ 'width' } ) ||
												$hash{ 'meta' } );
}

sub initBody {
    my $self = shift;
    $self->setTagContents( $body => new SMIL::Body( @_ ) ) unless $self->{$body};
}

sub startSequence {
    my $self = shift;
    $self->getContentObjectByName( $body )->startSequence( @_ );
}

sub startParallel {
    my $self = shift;
    $self->getContentObjectByName( $body )->startParallel( @_ );
}

sub endParallel {
    my $self = shift;
    $self->getContentObjectByName( $body )->endParallel();
}

sub endSequence {
    my $self = shift;
    $self->getContentObjectByName( $body )->endSequence();
}

sub hasQtExtensions {
				
				my $self = shift;
				my %hash = @_;
				my $returnValue = 0;
				
				foreach my $item ( keys %hash ) {
								$returnValue = 1 if $item =~ /^qt:/;
   }
				
				return $returnValue;
}

sub hasRnSmil2Extensions { 
				my $self = shift;
				
				my $returnValue = 0;
				
				my %the_hash = @_;
				
				foreach my $item ( keys %the_hash ) {
								foreach my $rnAttribute ( @rnSmil2Extensions ) {
												$returnValue = 1 if $item eq $rnAttribute;
								}
				}
				
				return $returnValue;
}

sub useRnSmil2Extensions { 
				my $self = shift;
				$self->setAttribute( $RN_SMIL_2_NS => $RN_SMIL_2_NS_URL );
}

sub hasSmil2Extensions { 
				my $self = shift;

				my $returnValue = 0;

				my %the_hash = @_;
				
				foreach my $item ( keys %the_hash ) {
								foreach my $rnAttribute ( @smil2Extensions ) {
												$returnValue = 1 if $item eq $rnAttribute;
								}
				}

				return $returnValue;
}

sub useSmil2Extensions { 
				my $self = shift;
				$self->setAttribute( $SMIL_2_NS => $SMIL_2_NS_URL );
}

sub checkForExtensions {
				
				my $self = shift;
				
    # Check for QT extensions, and add if necessary
    if( $self->hasQtExtensions( @_ ) ) {
								$self->useQtExtensions;
    }
				
				# Check for SMIL 2.0 attributes
				if( $self->hasSmil2Extensions( @_ ) ) {
								$self->useSmil2Extensions;
				}

				# Check for RN Smil 2.0 extensions
				if( $self->hasRnSmil2Extensions( @_ ) ) {
								$self->useRnSmil2Extensions;
				}

}

sub addInlinedMedia {
				my $self = shift;

				$self->addMedia( @_, inline => 1 );
}

sub addMedia {
    my $self = shift;

				$self->checkForExtensions( @_ );
				
    # Make sure that if we are adding inline that we
    # add the RP version checking code in case
    # we need to add a switch because we are authoring
    # for all players...
    if( &isInlined( @_ ) and $self->authoringBackwardsCompatible() ) {
								$self->useRnExtensions;
								# Add a switch statement of the possible entries here.
								$self->addBackwardsCompatibleSwitch( 'inline', @_ );
    }
    else {
								$self->getContentObjectByName( $body )->addMedia( @_ );
    }
}

sub getEarliestSupportedVersion {

   my $type = shift;
			my $feature = shift;

   print STDERR "Only RealPlayer is supported as backwards compatible type so far.: $type\n" 
							unless $type eq $RP_COMPATIBLE;

   return( $FEATURE_VERSION_MAPPING{ $type }->{ $feature } );  # $RP_VERSION_COMPONENT );

}

sub getSupportedVersionAttribute {

   my $version = shift;
   my $player = shift;

   print STDERR "Only RealPlayer supported as backwards compatible type so far.: $player\n" 
							unless $player eq $RP_COMPATIBLE;
			
   return( $CV_SYSTEM_COMPONENT, $VERSION_MAPPING{ $player }->[ $version ] );
			
}

sub getEarliestVersionForAttribute {
				my $attribute = shift;
				return $earliestAttribute{ $attribute };
}

sub addBackwardsCompatibleSwitch {
				
    my $self = shift;
				
				# Check for this 'feature' when adding switch code
				my $feature = shift;
    my @medias = ();
				
    my $earliestVersion = &getEarliestVersionForAttribute( $feature ); 
				# $self->getPrivate( $VERSION_COMPATIBLE ); # Don't really need this right now..
    my $playerType = $self->getPrivate( $PLAYER_COMPATIBLE );
				
				# Need a attribute list with the attribute we are switching on
				# and another without.
				my %withSwitchingAttribute = @_;
				
				# Remove the attribute
				my %withoutSwitchingAttribute = @_;
				undef( $withoutSwitchingAttribute{ $feature } );
				
    # Create a different media object for each of the versions
    # to support.  Make sure to go backwards since switch uses first
    # match
				my $supportedIndex = &getEarliestSupportedVersion( $playerType, $feature );
				
				my @attributes = ( %withSwitchingAttribute, 
																							( @RP_SYSTEM_REQUIRED_ATTRIBUTE, 
																									&getSupportedVersionAttribute( $supportedIndex, 	
																																																								$self->getPrivate( $PLAYER_COMPATIBLE ) ) ) );
				# attributes, and push it on the stack
				push @medias, SMIL::MediaFactory::getMediaObject( @attributes );
				
				# Now, add the one without the attribute
				push @medias, SMIL::MediaFactory::getMediaObject( %withoutSwitchingAttribute );
				
				# Create the different medias 
				$self->addSwitchedMedia( 'switch' => 'system-required',
																													medias => [ \@medias ] );
}

sub authoringBackwardsCompatible {
				my $self = shift;
				return( $self->getPrivate( $VERSION_COMPATIBLE ) and $self->getPrivate( $PLAYER_COMPATIBLE ) );
}

sub setBackwardsCompatible {
				
				my $self = shift;
				
				# Get a version number, if they gave it to us.
				my %args = @_;
				
				my $version = $args{ $VERSION_COMPATIBLE };
				
				my $player = $args{ $PLAYER_COMPATIBLE };
				
				# Only do it for RN players right now...
				if( $player eq $RP_COMPATIBLE ) {
								$self->setPrivate( $PLAYER_COMPATIBLE => $player );
								$self->setPrivate( $VERSION_COMPATIBLE => $version );
				}
				else {
								print STDERR "Backwards compatible only supported for RealPlayer so far.";
				}
}

sub isInlined {
				my %args = @_;  
				return defined( $args{ $INLINE } );
}

sub addTransition {
				my $self = shift;
				# Need to add the transition to the head.
				$self->useSmil2Extensions;
				my $head_ref;
				if( !( $head_ref = $self->getContentObjectByName( $head ) ) ) {
								$head_ref = new SMIL::Head();
								# Head must go at the top of the items in the <smil>
								$self->unshiftTagContents( $head => $head_ref );
				}
				$head_ref->addTransition( @_ );
}

sub addAnimation {
				my $self = shift;

				$self->useSmil2Extensions;

				die "addAnimation NYI";
}

sub addCode {
    my $self = shift;
    $self->getContentObjectByName( $body )->addCode( @_ );
}

sub addComment {
    my $self = shift;
    my $comment = shift;
    $self->getContentObjectByName( $body )->addCode( "<!--$comment-->" );
}

sub getRegionAttributeByName
{
    my $self = shift;
    my $region_name = shift;
    my $attr = shift;
    my $the_head = $self->getContentObjectByName( $head );
    my $return_value;
    if( $the_head ) {
	$return_value = $the_head->getRegionAttribute( $region_name, $attr );
    }
    if( 'ZERO_STRING' eq $return_value )
    {
	$return_value = "0";
    }
    return $return_value;
}

sub addSwitchedMedia {
    my $self = shift;
    $self->getContentObjectByName( $body )->addSwitchedMedia( @_ );
}

# Can only have one layout, so "set" rather than "add"
sub setSwitchedLayout {
    my $self = shift;
    if( $self->{$head} ) {
								$self->setTagContents( $head => new SMIL::Head( @_ ) );
    }
    $self->getContentObjectByName( $head )->setSwitchedLayout( @_ );
}

sub header {
    return "Content-type: " . &getMimeType() . "\n\n";
}

sub getMimeType {
				return "application/smil";
}

sub setMeta {
    my $self = shift;
    croak "Setting meta for SMIL NYI.";
}

sub setLayout {
    my $self = shift;
    croak "SetLayout for SMIL NYI.";
}

sub addRegion {
    my $self = shift;
    $self->getContentObjectByName( $head )->addRegion( @_ );
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Smil.pm - Perl extension for dynamic generation of SMIL files.

=head1 SYNOPSIS

 use Smil;
$s = new Smil;
$s->getAsString;

=head1 DESCRIPTION

This module provides an object oriented interface to generation of 
SMIL (Synchronized Multimedia Integration Language) files.  Creating
a simple SMIL file is as simple as this script:

 use Smil;
$s = new Smil;
print $s->header; # Remember MIME header if running as CGI
$s->addMedia( "src" => "rtsp://videoserver.com/video.rm" );
print $s->getAsString();

This will create the following SMIL file with the correct header, perfect
for a CGI script coming off a web server:

 Content-type: application/smil

 <smil>
    <body>
        <par>
            <ref src="rtsp://videoserver.com/video.rm"/>
        </par>
    </body>
 </smil>

Your first SMIL file!  Actually, this doesn't do much, but SMIL beginners 
can't be choosers, right?

As a new feature as of 0.70, you can now use Quicktime extensions.  Peruse the qt.pl file
in the installation directory for a sampling of the methods you can call for Quicktime
extensions added to the <smil> element.  Otherwise, add the attributes and their 
values directly into SMIL when you call addMedia.  Smil.pm will allow any namespace
attributes to pass through to the media element.  When you do add one of these attributes,
or call something like setQtAutoplay(), Smil.pm automatically adds the xmlns:qt attribute
with the proper unique identifier to the <smil> element.  So, if you decide midway through
creation of a SMIL file that you want Quicktime extensions, call the proper method and
Smil.pm will add the proper code to add these extensions to your SMIL file.

You can do more advanced things by adding regions to your SMIL files, and
playing media inside those regions.

    $s = new Smil( "height" => 300, "width" => 300 );
    $region_name = "first_region";
    $s->addRegion( "name" => $region_name, 
		   "top" => 20, "left" => 35, 
		   "height" => 100, "width" => 100 );
    $s->addMedia( "src" => "rtsp://videoserver.com/video.rm",
              "region" => $region_name );
    print $s->getAsString;

This code results in the following output:

 <smil>
    <head>
        <layout>
            <root-layout width="300" 
                         height="300"/>
            <region width="100" 
                    height="100" 
                    left="35" 
                    top="20" 
                    id="first_region"/>
        </layout>
    </head>
    <body>
        <par>
            <ref src="rtsp://videoserver.com/video.rm" 
                 region="first_region"/>
        </par>
    </body>
 </smil>

(Well, sort of, I had to reformat it so that it didn't stretch past the
end of the line, but functionally exactly the same)

All of this would be somewhat trivial if this module didn't expose the 
main differentiator between SMIL and HTML -- the timeline!  With SMIL
you can synchronize and schedule your media over a timeline, all 
without nasty proprietary scripting solutions.  This idea is built into 
SMIL and exposed in this module.

 $s = new Smil( "height" => 300, "width" => 300 );
 $region1 = "first_region";
 $region2 = "second_region";
 $s->addRegion( "name" => $region1, 
		"top" => 20, "left" => 35, 
		"height" => 100, "width" => 100 );
 $s->addRegion( "name" => $region2, 
		"top" => 60, "left" => 55, 
		"height" => 120, "width" => 120 );
 $s->startSequence();
 $s->addMedia( "src" => "rtsp://videoserver.com/video1.rm",
	       "region" => $region1 );
 $s->addMedia( "src" => "rtsp://videoserver.com/video2.rm",
	       "region" => $region2 );
 $s->endSequence();
 print $s->getAsString;

Results in this (again formatted to fit your screen...)

 <smil>
    <head>
        <layout>
            <root-layout width="300" height="300"/>
            <region width="100" height="100" 
                    left="35" top="20" 
                    id="first_region"/>
            <region width="120" height="120" 
                    left="55" top="60" 
                    id="second_region"/>
        </layout>
    </head>
    <body>
        <seq>
            <ref src="rtsp://videoserver.com/video1.rm" 
                    region="first_region"/>
            <ref src="rtsp://videoserver.com/video2.rm" 
                    region="second_region"/>
        </seq>
    </body>
 </smil>

You can schedule media in two ways, by calling startSequence coupled with 
endSequence or startParallel with endParallel, as you saw above, 
or you can specify begin and end times within the media directly for 
an absolute timeline.  

 $s = new Smil( "height" => 300, "width" => 300 );
 $region1 = "first_region";
 $region2 = "second_region";
 $s->addRegion( "name" => $region1, 
		"top" => 20, "left" => 35, 
		"height" => 100, "width" => 100 );
 $s->addRegion( "name" => $region2, 
		"top" => 60, "left" => 55, 
		"height" => 120, "width" => 120 );
 $s->startParallel();
 $s->addMedia( "src" => "rtsp://videoserver.com/video1.rm",
	       "region" => $region1 );
 $s->addMedia( "src" => "rtsp://videoserver.com/video1.rm",
	       "region" => $region2,
	       "begin" => "5s" );
 $s->endParallel();
 print $s->getAsString();

Producing this:

 <smil>
    <head>
        <layout>
            <root-layout width="300" height="300"/>
            <region width="100" height="100" 
                    left="35" top="20" id="first_region"/>
            <region width="120" height="120" 
                    left="55" top="60" id="second_region"/>
        </layout>
    </head>
    <body>
        <par>
            <ref src="rtsp://videoserver.com/video1.rm" 
                 region="first_region"/>
            <ref src="rtsp://videoserver.com/video1.rm" 
                 region="second_region" begin="5s"/>
        </par>
    </body>
 </smil>

Notice the "begin" parameter, this tells the media its absolute begin time.
The above code will start the second clip 5 seconds after the first even
though they are playing in parallel

You can add your own code using the addCode method

    $s->addCode( "<new_tag/>" );

You can add comments by using the addComment method

    $s->addComment( "A comment is here" );

PerlySMIL will add the necessary comment code around the comment, so you 
get back

<!--A comment is here-->

You as the author are responsible for formatting, so don't expect that
your arbitrary code will be indented like the rest of the SMIL.

Like HTML, SMIL applications can have hyperlinks.  There are two types in 
SMIL: normal hrefs, and anchors.  An href covers the entire media item, 
whereas an anchor covers a rectangular portion of the media item.  To create
an href, add the "href" parameter when you add the media to the 
SMIL object.

 $s->addMedia( "src" => "rtsp://videosource.com/video.rm",
               "show" => "new",
               "href" => "http://www.destinationlink.com/link.html" );

Adding anchors is more complex, but much more versatile.  You can do 
everything with anchors that you can do with hrefs, but with anchors
you add the capability to change the hyperlinks over time and specify
only portions of the media item for linking.  To create an anchor
you need to pass, brace yourself, a reference to an array of hash references.
Mimic the code below if you don't want to know what that means.  The format 
is like this:

[ { hash_values }, { hash_values } ] where hash_values are key-value
pairs like "bob" => "sally"  (Perl gurus know that "=>" is a synonym for
comma...)

Here's a code example to get you started.

    $smil->addMedia( 'src' => "video.rm",
		     'anchors' => 
                        [ 
                          { 'href' => "http://websrv.com/index.html, 
                              'coords' => '0,0,110,50',
			      'show' => 'new',
			      'begin' => 3 } ,
                          { 'href' => "another.smil",
			      'coords' => '125,208,185,245',
			      'begin' => 9 } 
                        ] );

Notice several things about the above example.  One, with an anchor, we
can specify where we want the hyperlink to persist over the media item.  
This is done using a coordinate system with two points, the top, left 
corner, and the bottom, right corner.  So, if we wanted to remove the 
href tag completely, we could just specify the entire canvas of the media
item in the coordinate parameter and we would have the same thing as a href.
Also, in the above example, we started some hyperlinks at different times.
The first one begins a 3 seconds, and the second begins at 9 seconds.  We
could have also specified end times using the "end" parameter/attribute.
Finally, since a SMIL is not HTML we have to have a mechanism for dealing
with links to HTML files (or other media for that matter) and media that
can play back within our SMIL player.  So, if we want to send the result
of clicking on a link to a web browser, we need to use the "show" parameter
and give it a value of "new".  If we want our SMIL player to handle the
hyperlink itself (as would be the case for the second example since it is
another smil file), we can either leave the "show" parameter out and let 
it default to the SMIL player, or explicitly add "show" => "replace" to
replace the current SMIL file with the new link.

As a new feature of 0.7, you can now inline your media files directly within 
a SMIL file.  When you add media to smil using the addMedia method call, 
specify inline => 1 and the module will attempt to download or read from
local disk any files which are added using this attribute.  Check out the 
inline.pl file inside the installation directory, and also the slurp.pl 
script which will slurp in simple SMIL files and inline all code if you give
it the proper parameter.

=head1 METHODS 

This is a comprehensive listing of all the methods exposed by Smil.pm.

=head2 Basic Smil functionality

addMedia(): this method adds a media reference or other to a SMIL 
document.  It is best to read the above documentation on addMedia since there
are many parameters available.  You should always have a "src" key/value
pair at the very least.  "src" can be a reference to a local file, 
a reference to a remote file (http:// or rtsp://, for example), or 
it can be a object reference, for any object which supports the 
getAsString() and getMimeType() method interface.  RN::RealText is one 
example, but any one can write their own class and use it here.  Peruse 
the sample scripts in the installation directory for examples.

addRegion(): this method adds a region for media playback.  The only
required attribute is "name" (or "id" which is synonymous) which uniquely
identifies the region, and should be a name starting with a letter, 
composed of alphanumeric characters.  For SMIL files which will be played
back in a SMIL 1.0 compliant player you should also use the attributes
"height" and "width".  "z-index" specifies the stacking order of the media
regions and is optional.  Refer to the documentation above for more 
information on addRegion, and peruse the sample scripts in the installation
directory for other examples.

getAsString(): this method returns the SMIL file as a string.  It takes no
parameters.  Once you have finished composing your SMIL file, you 
retrieve the code with this method.

startSequence(): this method starts a sequence of media references, or 
grouping of media references, where each piece of media will be played 
in succession, one after the other.  Compare to startParallel.  It takes
no parameters.

startParallel(): this method starts a grouping of media references where
each piece of media will be played with the same beginning time.  Compare
to startSequence.  It takes no parameters.

endParallel(): end a media group.  Every call to startParallel() should
be matched by a call to endParallel, although if all media have been
added this call can be safely omitted and Smil.pm will add the proper
number of closing <par> tags.  It takes no parameters.

endSequence(): end a media sequence.  Every call to startSequence() should
be matched by a call to endSequence, although if all media have been
added this call can be safely omitted and Smil.pm will add the proper
number of closing <seq> tags.  It takes no parameters.

addCode(): this method allows arbitrary code snippets in SMIL.  If a 
feature of SMIL is not supported by the exposed methods of the Smil.pm
module, code for that feature can be added using this method.  It takes
a string as its only parameter.

addComment(): this method allows commenting in SMIL files.  It takes a 
string as its only parameter.

getRootHeight(): convenience method to retrieve the height of the SMIL
file.

getRootWidth(): convenience method to retrieve the width of the SMIL
file.

header(): convenience method which returns the MIME type for SMIL;
useful when the perl script is running as a CGI program.

=head2 Advanced Smil functionality

addInlinedMedia(): this method has the same parameter options as addMedia()
but it automatically generates the extra parameters to inline the media 
directly within the SMIL file.

addSwitchedMedia(): this method allows a user to add several pieces of 
media to SMIL such that one piece will be displayed in one configuration
or version of a media player, and another piece of media will be displayed
in another.

setSwitchedLayout(): this method adds a switched layout to SMIL, so 
that one player version or player configuration can display a different layout
than another player version or player configuration.

setBackwardsCompatible(): call this method if you want the Smil.pm module
to automatically generate SMIL code which is backwards compatible.  In 
general this method is useful for small SMIL files, or prototyping, 
because the module is not especially smart about optimizing switch 
statements.  You must call this with two parameters, "player" => <name> and
"version" => <number>.  Right now only "player" => "rp" RealPlayer) is 
supported for backwards compatibility, since it is the only player I know of
which has players with different compatibility levels for SMIL.

=head2 RealNetworks extensions

useRnExtensions(): call this method to guarantee that the RealNetworks 
namespace will be added to the <smil> tag.  Normally this method
will be called automatically for you when you use SMIL features
that require it, but if you add your own code and need to use this
namespace it is available.

=head2 Quicktime extensions

setQtAutoplay(): this method tells the Quicktime player to automatically
start playing the presentation once the SMIL has been loaded.  Refer
to the Quicktime documetation for more details on this feature.

setQtChapterMode(): Refer to the Quicktime documentation for more details
on this feature.

useQtImmediateInstantiation(): Refer to the Quicktime documentation for 
more details on this feature.

setQtNextPresentation():  this method tells the Quicktime player to load
another presentation once this SMIL presentation is finished.  Refer 
to the Quicktime documentation for more details on this feature.

useQtTimeSlider(): this method tells the Quicktime player to enable the
time slider.  Refer to the Quicktime documentation for more details 
on this feature.

hasQtExtensions(): this method returns true or false depending on whether
the SMIL document is using Quicktime extensions.

useQtExtensions(): this method will normally be called when one of the
above methods is used.  It adds the quicktime namespace to the SMIL
document so that Quicktime extensions can be used.

=head2 SMIL 2.0 extensions

addTransition(): this method adds a transition to the SMIL file.  

addAnimation(): this method is currently under development for SMIL 2.0
extensions.

useRnSmil2Extensions(): this method adds a RN specific namespace to the 
SMIL file which can be used to add RealNetworks SMIL 2.0 extensions. 
It is most often called internally by the Smil.pm module when it encounters
media which attempt to use RealNetworks SMIL 2.0 extensions.

useSmil2Extensions():  this method adds the SMIL 2.0 namespace to the SMIL
file which allows a SMIL renderer/player to verify that this code has SMIL 
2.0 features.  It is most often called internally by the Smil.pm module
when it encounters media references which attempt to use generic SMIL 2.0 
extensions.

=head1 AUTHOR

Chris Dawson (cdawson@webiphany.com)
http://www.webiphany.com/perlysmil/

=head1 SEE ALSO

perl(1). perldoc RN::RealText, perldoc CGI 

=cut
