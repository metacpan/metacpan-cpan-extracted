package SMIL::MediaResolver;

$VERSION = "0.898";

my %typeLookupHash = (
		      'smil' => 'application/smil',
		      'rt' => 'text/vnd.rn-realtext',
		      'rp' => 'image/vnd.rn-realpix',
		      'swf' => 'image/vnd.rn-realflash',
		      'gif' => 'image/gif',
		      'jpg' => 'image/jpeg',
		      'jpeg' => 'image/jpeg',
		      'rm' => 'audio/vnd.rn-realvideo',
		      'ra' => 'audio/vnd.rn-realvideo',
		      'txt' => 'text/plain',
		      'html' => 'text/html',
		      'htm' => 'text/html',
		      );


sub resolveTypeFromUrl {
    
    my $type = "";
    my $url = shift;
    
    @results = &LWP::Simple::head( $url );
    $type = $results[ 0 ];	
    
    return $type;
    
}

sub getContent {
    my $self = shift;
    
    eval 'use LWP::Simple;';
    my $lwpInstalled = !$@;
    
    my $content = "";
    my $type = "";
    
    my $thisSrc = $self->getAttribute( "src" );
    
    if( ref( $thisSrc ) ) {
	# I cannot figure out how to define an interface base class
	# and then derive all my concrete classes from it and
	# maintain the interface transparently.  So, just eval
	# the function call on this object and if it fails, well, it 
	# obviously wasn't the proper type.
	eval { 
	    $content = $thisSrc->getAsString(); 
	    $type = $thisSrc->getMimeType();
	    
	};
	
    }
    elsif( $thisSrc ) {
	if( $thisSrc =~ /^http:/ and $lwpInstalled ) {
	    $content = &LWP::Simple::get( $thisSrc );	
	    $type = &resolveTypeFromUrl( $thisSrc );
	}
	elsif( $thisSrc !~ /^http:/ ) {
	    # Assume it comes from disk
	    if( open CONTENT, $thisSrc ) {
		binmode CONTENT;
		undef $/;
		$content = <CONTENT>;
	    }
	    
	    # Lookup the type based on filename
	    $type = &lookupType( $thisSrc );
	}
    }
    
    return( $content, $type );
}

sub lookupType {
    my $filename = shift;
    # get filename extension
    $extension = $1 if $filename =~ /\.(.*?)$/;
    
    # Lowercase it
    $extension = "\L$extension";
    
    return $typeLookupHash{ $extension };
}

1;

