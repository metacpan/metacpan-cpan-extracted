package SMIL::Layout;

my $debug = 1;

$VERSION = "0.898";

use SMIL::XMLContainer;
use SMIL::RootLayout;
use SMIL::Region;
use SMIL::SystemSwitches;

@ISA = qw( SMIL::XMLContainer );

use Carp;
my $regions = "regions";
my $module_defined_src = "sm-src";
my $module_defined_align = "sm-align";
my $left_offset = "sm-left-offset";
my $top_offset = "sm-top-offset";
my $switch_target = "switch-target";
my @rootLayoutAttributes = ( 'height', 'width', 'background-color' );
my @layoutAttributes = @systemSwitchAttributes;

my $CENTER = 'center';
my $LEFT = 'left';
my $RIGHT = 'right';

my $root_layout = "root-layout";

sub getRootHeight {
    my $self = shift;
    my $rl = $self->getContentObjectByName( $root_layout );
    return $rl ? $rl->getRootHeight() : 0;    
}

sub getRootWidth {
    my $self = shift;
    my $rl = $self->getContentObjectByName( $root_layout );
    return $rl ? $rl->getRootWidth() : 0;    
}

sub init {
    my $self = shift;
    $self->SUPER::init( "layout" );
    my %hash = @_;

    if( $hash{ $switch_target } ) {
	$self->setAttributes( $hash{ $switch_target } => 
			      $hash{ $hash{ $switch_target } } );
    }

    my %layoutAttrs = $self->createValidAttributes( { %hash },
						    [ @layoutAttributes ] );

    $self->setAttributes( %layoutAttrs );

    # Grab height and width from the hash if we don't have root-layout
    my %rootLayoutAttrs;
    if( !$hash{ root_layout } ) {
	%rootLayoutAttrs = 
	    $self->createValidAttributes( { %hash },
					  [@rootLayoutAttributes] );
    }
    else {
	my $rl_hash = $hash{ root_layout };
	%rootLayoutAttrs = 
	    $self->createValidAttributes( { %$rl_hash }, 
					  [@rootLayoutAttributes] );
    }

    $self->{$root_layout} = new SMIL::RootLayout;
    $self->{$root_layout}->setAttributes( %rootLayoutAttrs );
    $self->setTagContents( $root_layout => $self->{$root_layout} );
}

my $name = 'name';
my $id = "id";
my @regionAttributes = ( $id, 'top', 'left', 'height', 'width', "fit",
			'z-index', 'background-color', );

sub process_for_size {
    my $type = shift;
    my $content = shift;
    my( $height, $width );

    if( $type =~ /gif/i || $content =~ /^GIF/ ) {
	my $string = $1 if $content =~ /GIF.{3}(.{4})/;
	@stuff = unpack "SS", $string;
	$height = $stuff[ 1 ];
	$width = $stuff[ 0 ];
    }
    elsif( $type =~ /jpe?g/i ) {
	warn "JPEG images unsupported for region dimension calculation.";
    }
    elsif( $type eq "rt" || $type =~ /rn-realtext/ ) {
	( $height, $width ) = ( $1, $2 ) 
	    if $content =~ /<window[^>]*height="(\d*)"[^>]*?width="(\d*)"/;
	( $height, $width ) = ( $2, $1 ) 
	    if ( !$height and !$width ) and
		$content =~ /<window[^>]*width="(\d*)"[^>]*?height="(\d*)"/;
	die "Couldn't find height and width in RealText file." 
	    unless $height and $width;
    }
    elsif( $type eq "rp" || $type =~ /rn-realpix/ ) {
	( $height, $width ) = ( $1, $2 ) 
	    if $content =~ /<head[^>]*height="(\d*)"[^>]*?width="(\d*)"/;
	( $height, $width ) = ( $2, $1 ) 
	    if ( !$height and !$width ) and
		$content =~ /<head[^>]*width="(\d*)"[^>]*?height="(\d*)"/;
	die "Couldn't find height and width in RealText file." 
	    unless $height and $width;
    }

    return( $height, $width );
}

sub getRegion
{
    my $self;
    $self = shift;
    my $region_name;
    $region_name = shift;
    my $the_regions;
    $the_regions = $self->getContentObjectByName( $regions );
    if( !( $the_regions && @$the_regions ) ) {
	$the_regions = [];
	$self->setTagContents( $regions => $the_regions );
    }
    my $return_region;
    if( $the_regions and @{$the_regions} ) {
	foreach my $the_region ( @{$the_regions} ) {
	    if( $the_region and 
		( $region_name eq $the_region->getAttributeValue( 'id' )
		  or $region_name eq $the_region->getAttributeValue( 'name' ) ) ) {
		$return_region = $the_region;
	    }
	}
    }
    return $return_region;
}

sub addRegion {
    my $self = shift;
    my %hash = @_;

    # Now, set up the new SMIL::region
				
    # If they used "name" instead of "id" fix that
    $hash{ $id } = $hash{ $name } if $hash{ $name };
				
    # If they specified the src inside the region, then
    # figure out the dimensions from the src file
    if( $hash{ $module_defined_src } ) {
	my $ref = $hash{ $module_defined_src };
	my $content;
	my $type;
	
	# If a http ref, if we have LWP installed use it to
	# get the image and determine the dimensions
	if( $ref =~ /^http/ ) {
	    eval 'use LWP::Simple;';
	    my $lwp_installed = !$@;
	    
	    if( $lwp_installed ) {
		$content = LWP::Simple::get $ref;
		
		# Also, get the type if possible
		$type = head( $ref );
	    }
	    else {
		die "LWP not installed.\nYou may not use http sources" .
		    " in your region definitions.\nSmil.pm cannot " .
		    "connect and determine file size without LWP\n";
	    }
	}
	else {
	    # Ok, hope it is local to the script.
	    if( open FILE, $ref ) {
		binmode FILE;
		undef $/;
		$content = <FILE>;
		close FILE;
	    }
	    else {
		die "Couldn't find the file $ref.\n" .
		    "Make sure that $ref is relative to the script.\n" .
		    "Using src to define a region does not set the\n".
		    "src for the SMIL file but is used to " .
		    "determine\nfile size.\n";
	    }
	    
	    # Determine the type from the extension
	    $type = "\L$1" if $ref =~ /\.(\w*)$/;
	}
	
	if( $content ) {
	    # Figure out what the size is 
	    ( $height, $width ) = process_for_size( $type, $content );
	    
	    if( $height && $width ) {
		# Always respect what users set.
		$hash{ height } = $height unless defined( $hash{ height } );
		$hash{ width } = $width unless defined( $hash{ width } );
	    }
	}
    }
    
    # Now, if we have some formatting in the "sm-align" attribute
    # figure out the top or left.
    if( $hash{ $module_defined_align } ) {
	# Get the root layout object
	my $ht = $self->getRootHeight();
	my $wh = $self->getRootWidth();
	
	# Calculate the top and left unless they are set already
	die "Need height to calculate alignment." 
	    unless defined( $hash{ height } );
	if( 'middle' eq $hash{ $module_defined_align } and
	    !defined( $hash{ top } ) ) {
	    # Figure out where to put this item
	    # Get the total size / 2 minus the item size / 2
	    $hash{ top } = int( ( $ht / 2 ) - ( $hash{ height } / 2 ) );
	}
	
	die "Need width to calculate alignment. " 
	    unless defined( $hash{ width } );
	if( !defined( $hash{ left } ) ) {
	    if( $hash{ $module_defined_align } =~ /center/i ) {
		# Get the total size / 2 minus the item size / 2
		$hash{ left } = int( ( $wh / 2 ) - ( $hash{ width } / 2 ) );
	    }
	    elsif( $hash{ $module_defined_align } =~ /right/i ) {
		# Get the width - size of the element
		$hash{ left } = $wh - $hash{ width };
	    }
	    elsif( $hash{ $module_defined_align } =~ /left/i ) {
		# easy enough...
		$hash{ left } = 0;
	    }
	}

	if( defined( $hash{ left } ) && defined( $hash{ $left_offset } ) ) {
	    $hash{ left } += $hash{ $left_offset };
	}
	
	if( defined( $hash{ top } ) && defined( $hash{ $top_offset } ) ) {
	    $hash{ top } += $hash{ $top_offset };
	}
    }
    
    my %attrs = $self->createValidAttributes( { %hash },  
					      [@regionAttributes] );
    $ZERO_STRING = "ZERO_STRING";
    my $region = new SMIL::Region;
    $region->setAttributes( %attrs );
    $region->setAttribute( 'top' => $ZERO_STRING ) unless $hash{ 'top' };
    $region->setAttribute( 'left' => $ZERO_STRING ) unless $hash{ 'left' };
    
    my $current_regions = $self->getContentObjectByName( $regions );
    
    if( !( $current_regions && @$current_regions ) ) {
	$current_regions = [];
    }
    
    # If error checking is set to true, check to see if the new
    # region has the same name as a previously existing region
    if( $check_errors ) {
	foreach $reg ( @$current_regions ) {
	    croak "Region \"" . $attrs{ $id } . 
		"\" has the same name as another existing region"
		    if $attrs{ $id } && 
			$reg->getAttribute( $id ) eq $attrs{ $id };
	}
    }
    
    push @$current_regions, $region;
    $self->setTagContents( $regions => $current_regions );
}






