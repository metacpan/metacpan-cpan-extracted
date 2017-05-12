package Podcast::UploadManager;
@ISA = qw( Podcast::LoggerInterface );

use Net::FTP;

$VERSION="0.51";

sub new { 
    my $class = shift;
    my $self = {};
    bless ( $self, $class );
    return $self;
}

sub init {
    my $self = shift;
    my $attr = shift;
    $self->{ 'host' } = $attr->{ 'host' } || $attr->{ 'hostname' };
    $self->{ 'username' } = $attr->{ 'username' };
    $self->{ 'password' } = $attr->{ 'password' };
    $self->{ 'path' } = $attr->{ 'path' };
    $self->{ 'protocol' } = $attr->{ 'protocol' } || 'ftp';    
    $self->{ 'remote_root' } = $attr->{ 'remote_root' };
    $self->{ 'remote_root' } .= "/" unless $self->{ 'remote_root' } =~ /\/$/;
}

sub DESTROY { 
    my $self = shift;
    $self->{ 'ftp_handle' }->quit if $self->{ 'ftp_handle' };
    $self->{ 'ftp_handle' } = 0;
}

sub clean {
    my $self = shift;
    my $items = shift;

    if( $self->{ 'clean' } ) {
	my $ftp = $self->{ 'ftp_handle' };
	if( $ftp ) {
	    # Go over each MP3 file, and delete if we are past expiration
	    # and the file is not in our list
	    my @remote_files = grep /\.mp3$/, $ftp->ls();
	    
	    # Iterate over each one, pull out the ones we have in the podcast
	    foreach my $to_delete ( @remote_files ) {
		
		# Make sure we don't have this in the current podcast
		my $dont_delete = 0;
		foreach my $current ( @{$items} ) {
		    $dont_delete = 1 if $to_delete =~ /$current->{'mp3'}/;
		}
		
		if( not $dont_delete ) {
		    my $do_delete = 0;
		    # If we want to delete it, make sure expiration date is OK
		    my $now = time;
		    my $expiration = $self->{ 'clean_expiration' };
		    if( $expiration ) {
			if( $expiration < ( $now - $ftp->mdtm( $to_delete ) ) ) {
			    $self->log_message( "Elapsed time: " . ( $now - $ftp->mdtm( $to_delete ) ) .
						" vs. $expiration" );
			    $do_delete = 1;
			}
		    }
		    else {
			$do_delete = 1;
		    }
		    
		    if( $do_delete ) {
			$self->log_message( "Deleting from remote site: $to_delete and MD5 hash" ); 
			$ftp->delete( $to_delete ); 
			$ftp->delete( $to_delete . ".md5" ); 
		    }
		}
	    }
	}
    }
}

sub set_cleanup {
    my $self = shift;
    my $hash = shift;
    $self->{ 'clean' } = $hash->{ 'clean' };
    $self->{ 'clean_expiration' } = $hash->{ 'expires' };
}

sub get_upload_pref {
    my $self = shift;
    my $key = shift;
    my $rv = $self->{ 'alt_upload' } ? $self->{ 'alt_upload' }->{ $key } : $self->{ $key };
    return $rv;
}

sub ftp_upload
{
    my $self = shift;
    my $item = shift;
    # $self->log_message( "Inside ftp upload" );
    my $file = ( $item->{ 'xml' } ? $item->{ 'xml' } : 
		 ( -e $item->{ 'mp3' } ? $item->{ 'mp3' } : 
		   ( $item->{ 'local_root' } . $item->{ 'mp3' } ) ) );
    my $short_name = $1 if $file =~ /\/([^\/]+)$/;

    # Create ftp object if not there
    use Net::FTP;
    $self->{ 'ftp_handle' } = new Net::FTP( $self->get_upload_pref( 'host' ) ) 
	unless $self->{ 'ftp_handle' };
    my $ftp = $self->{ 'ftp_handle' };
    
    if( $ftp ) {
	# Disable these for now, since we often get without true error
	# $self->log_message( "Unable to login with username: " . $self->{ 'username' } .
	#", message: " . $ftp->message ) 
	# unless 
	$ftp->login( $self->get_upload_pref( 'username' ), $self->get_upload_pref( 'password' ) );
	# $self->log_message( "Unable to move to " . $self->{ 'path' } . 
	# ", message: " . $ftp->message ) 
	#unless 
	$ftp->cwd( $self->get_upload_pref( 'path' ) );
	
	$ftp->binary();
	
	my $size = -s $file;
	$return_value = $self->upload_if_necessary( $ftp, $short_name, $file );
	
	# Disabled for now, sizes seem different regardless, bytes might be 
	# incorrectly reported.
	if( 0 && $self->get_upload_pref( 'remote_root' ) ) {
	    # Verify the file is there
	    use LWP::Simple;
	    my $full_path = $self->get_upload_pref( 'remote_root' ) . $short_name;
	    my @result = head( $full_path );
	    $self->log_error( "Remote size ($result[1] vs $size) and local sizes are " .
			      "different [$full_path]" )
		unless $result[ 1 ] == $size;
	}
    }
    return $return_value;
}

sub check_success {
    my $self = shift;
    my $out = shift;
    my $success = 0;
    if( open OUTPUT, $out ) {
	undef $/;
	my $file = <OUTPUT>;
	$success = $file !~ /unsuccessful/i;
	$self->log_message( "Logged in successfully" ) if $success;
    }
    return $success;
}


sub piab_upload {
    my $self = shift;
    my $item = shift;
    my $return_value = 0;
    # print "Inside piab upload".
    # Don't upload any XML files
    return if $item->{ 'xml' };
    my $file = -e $item->{ 'mp3' } ? $item->{ 'mp3' } : 
	( $item->{ 'local_root' } . $item->{ 'mp3' } );
    # Don't upload if we've already done this.
    return 1 if $item->{ 'uploaded' };
    # Get a temp file for the cookies
    my $cookies = "/tmp/" . time() . ".piab-cookies.tmp";
    my $out = "/tmp/" . time() . ".out.tmp";

    eval {
	my $host = $self->get_upload_pref( "host" );
	my $username = $self->get_upload_pref( "username" );
	my $password = $self->get_upload_pref( "password" );
	my $login_url = "https://$host/user/login";
	my $create_url = "https://$host/episode/create";
	# Login first
	my @args = ( "curl", "-c", $cookies,
		     "-k", "-s", "-d", 
		     "user[login]=$username",
		     "-d",
		     "user[password]=$password",
		     ( $login_url || "https://podasp.com/user/login" ),
		     "-o", $out );
	my $cmd_str = join " ", @args;
	$cmd_str =~ s/user\[login\]=\S+/user\[login\]=xxxx/;
	$cmd_str =~ s/user\[password\]=\S+/user\[password\]=xxxx/;
	$self->log_message( "Commands for login: " . $cmd_str );
	# Check to see if the out file indicates success or failure

	if( 0 == system( @args ) and check_success( $self, $out ) ) {
	    $self->log_message( "Logged in" );
	    # Get the metadata
	    my $scrubbed_title = $item->{ 'title' };
	    $scrubbed_title = "Upload from PIAB" unless $scrubbed_title;
	    my $scrubbed_description = $item->{ 'description' };
	    $scrubbed_description = ( "Upload from PIAB, IP " . WIAB::Network::get_ip() . ", on " 
				      . Class::Date::now() ) unless $scrubbed_description;
	    my $scrubbed_podcast = $item->{ 'associated_podcast' };
	    @args = ( "curl", "-b", $cookies, "-c", $cookies,
		      "-H", "Expect:",
		      "-k", "-s", "-o", '/dev/null',
		      "-F", "episode[title]=$scrubbed_title",
		      "-F", "episode[description]=$scrubbed_description",
		      ( $scrubbed_podcast ? ( "-F", "episode[podcast]=$scrubbed_podcast" ) : () ),
		      "-F", "episode_mp3_file=\@" . $file,
		      $create_url
		      );
	    $self->log_message( "Commands for creation: " . join " ", @args );
	    if( 0 == system( @args ) ) {
		$self->log_message( "Created file [$item->{'mp3'}]" );
		$return_value = 1;
	    }
	    else {
		$self->log_error( "Unable to create file" );
	    }
	}
	else {
	    $self->log_message( "Unable to login: $!" );
	}
    };

    # Make sure to delete these files.
    unlink $cookies;
    unlink $out;
    return $return_value;
}

sub upload {
    my $self = shift;
    my $item = shift;
    $self->{ 'alt_upload' } = shift;
    my $return_value = 0;
    my $protocol = $self->get_upload_pref( 'protocol' );
    if( $protocol eq 'ftp' ) {
	$return_value = $self->ftp_upload( $item );
    }
    elsif( $protocol eq 'piab' ) {
	$return_value = $self->piab_upload( $item );
    }
    elsif( $protocol eq 'off' ) {
	$return_value = 1;
    }
    return $return_value;
}

sub upload_if_necessary {

    my $self = shift;
    my $ftp = shift;
    my $short_name = shift;
    my $file = shift;
    my $return_value = 0;
    
    my $skip_upload = 0;
    # Get the message hash, to be sure.
    my $remote_digest_filename = "/tmp/" . $short_name . ".md5";
    $self->log_message( "Unable to find MD5 file for $remote_digest_filename" ) unless 
	$ftp->get( $short_name . ".md5", $remote_digest_filename );
    
    # OK, got remote digest, now check local one
    $ctx = Digest::MD5->new;
    if( open FILE, $file ) {
	$ctx->addfile( *FILE );
    }
    $local_digest = $ctx->hexdigest;
    
    my $remote_digest;
    if( -e $remote_digest_filename ) {
	# Read in the local remote digest, to compare
	$fh = new IO::File;
	if( $fh->open("< $remote_digest_filename") ) {
	    $remote_digest = <$fh>;
	    $fh->close;
	}
	# $self->log_message( "Hash: $remote_digest" );;
    }
    
    # Now, use the same filename to write the new digest
    my $fh = new IO::File;
    if( $fh->open( "> $remote_digest_filename" ) ) {
	print $fh $local_digest;
	$fh->close();
	# $self->log_message( "Wrote new digest: $local_digest" );
    }	
    
    if( $local_digest eq $remote_digest ) {
	$skip_upload = 1;
    }
    else {
	$self->log_message( "MD5 hash mismatch ($local_digest vs $remote_digest)" );
    }

    if( not $skip_upload ) {
	$self->log_message( "Uploading $file and $remote_digest_filename" );
	if( $ftp->put( $file ) and
	    $ftp->put( $remote_digest_filename ) ) {
	    $return_value = 1;
	    $self->log_message( "Uploaded $file and $remote_digest_filename" );
	}
	else {
	    $self->log_error( "Unable to upload $file and $remote_digest_filename" );
	}
    }
    else { 
	# $self->log_message( "MD5 matches" );
	$return_value = 1;
    }

    return $return_value;
    
}


1;
