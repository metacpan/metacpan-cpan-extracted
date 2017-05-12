package Podcast::Publisher;
@ISA = qw( Podcast::LoggerInterface );

use Carp;
use XML::Simple;
use IO::File;
use Date::Format;
use XML::Writer;
use DBI;
use Podcast::UploadManager;
use Podcast::LoggerInterface;
use Digest::MD5;

my $DEFAULT_CONF = '.piab/podcastcfg.xml';
my $DEFAULT_DB_CONF = '.piab/dbcfg.xml';
my $_upload_info;

$VERSION="0.51";

=pod

=head1 NAME

Podcast::Publisher - Module for creating and managing podcasts

=head1 SYNOPSIS

=over

 use Podcast::Publisher;

 my $podcast = Podcast::Publisher->new;
 $podcast->set_logger( sub { my $msg = shift; print $msg; } );
 $podcast->set_error_logger( sub { my $msg = shift; print STDERR $msg; } );
 my $xml = "./podcast.xml";
 $podcast->set_file( $xml );
 $podcast->set_remote_root( "http://localhost.localdomain/podcast/publishing/" );
 $podcast->set_db_connection( { 'driver' => "mysql", 
				'username' => 'foo',
				'password' => 'bar',
				'host' => 'localhost',
				'database' => 'podcast' } );

 # If we change podcast information, synchronize this information in the MP3 file itself
 $podcast->set_synchronize( 1 );

 $podcast->set_metadata( { 'title' => "Chris' Podcast",
			  'description' => "All About Chris",
			  "docs" => "http://localhost",
			  "editor" => "podcastmanager\@localhost",
			  "webmaster" => "podcastmanager\@localhost",
		      } );

 # This adds an item to the database, and synchronizes the 
 # MP3 Tag information in the file with the database
 $podcast->add_new_episode( { 'title' => 'Some title',
			      'author' => 'Chris of course'
			      'category' => 'Jazz'
			      'description' => 'First in a series of many'
			      'mp3' => '/home/foobar/mp3s/episode1.mp3' } );

 $podcast->set_upload_settings( { 'host' => 'localhost.localdomain',
				  'username' => 'someuser',
				  'password' => 'somepass',
				  'path' => 'podcast/publishing/',
				  'remote_root' => 'http://localhost.localdomain/podcast/publishing/' } );
 $podcast->upload();

=head1 AUTHOR

Chris Dawson, chris aT webcastinabox d0t c0m

=head1 COPYRIGHT AND LICENSE

(c) Webcast in a Box, Inc 2005

This library is free software; you can redistribute it and or modify
it under the same terms as Perl itself. 

=head1 DESCRIPTION

Podcast::Publisher is an object oriented library which can
dynamically construct podcast xml feeds with item
metadata tagging, enclosure byte length calculations,
automatic and transparent MP3 tag information synchronization,
intelligent file upload management, and process logging. 
This library is also available at http://podcast.webcastinabox.com. 

This library requires a database (currently supports MySQL, probably postgres as well).

=over 4

=head1 BUGS

Some metadata is not stored properly in the MP3 file if you use synchronization, but this will
be fixed very soon.

=head1 METHODS

=item new()

$podcast = Podcast::Publisher->new();

Creates a podcast object.  

=cut

sub new {
    my $class = shift;
    my $self = {};
    $self->{ 'maximum_episodes' } = 15;
    $self->{ 'piab_upload_root' } = "/opt/wiab/text_data/piab_upload";
    bless ( $self, $class );
    return $self;
}

=item upload()

$podcast->upload();

Uploads all files to the proper location.  Each episode MP3 file is uploaded.  The upload()
method intelligently uploads files based on an MD5 digest hash of the file.  If it is the
first time the file has been uploaded, the file is uploaded, and a MD5 digest hash file
is uploaded alongside it.  The next time, the digest hash is generated again, and compared
against the file on the server.  If the digest hash changes (if the MP3 file changes size,
or the metadata changes) then the file is uploaded again.  If the file has not changed,
then the upload is skipped.  Finally the podcast.xml file is uploaded.

=cut

sub upload { 
    my $self = shift;

    # $self->log_message( "Entering upload" );
    
    $self->log_error( "Must call set_upload_settings to establish upload settings first" )
	unless $self->{ 'upload_handle' };

    # Upload all files
    my $items = $self->get_episodes();
    
    # $self->log_message( "Found episodes: " . scalar( @{$items} ) );

    # Create upload object

    foreach my $item ( @{$items} ) {
	my $ui = $_upload_info[ $item->{ 'id' } ];
	$item->{ 'local_root' } = $self->{ 'local_root' };
	if( $self->{ 'upload_handle' }->upload( $item, $ui ) ) {
	    $self->set_uploaded_status( $item );
	}
	else {
	    $self->log_error( "Cannot upload mp3: " . $item->{ 'mp3' } );
	}
    }
    
    # Uplaod the RSS file
    $self->{ 'upload_handle' }->upload( { 'xml' => $self->{ 'filename' } } );
    $self->{ 'upload_handle' }->clean( $items );
}

=item enable_cleanup( ... )

$podcast->enable_cleanup( { ... } );

This method allow you to tell the publisher to delete files on the remote server
which are no longer in the podcast.  If called with no parameters, it deletes all 
files on the remote server which are not in the podcast RSS file.  If someone who 
recently grabbed your podcast RSS is downloading an MP3 from a podcast file which 
you just updated, this could cause strange errors.  To remedy this you can provide 
a hashref with the 'expires' parameter to indicate how many seconds out of date a 
file can be before deletion.  So, if you call enable_cleanup() like this:

    $podcast->enable_cleanup( { 'expires' => 7 * 24 * 60 * 60 } );

you'll delete files which are not stored in the podcast RSS, and are older than a week.  While
this doesn't guarantee that you didn't just modify a podcast RSS, it gives you a little more
leeway.  This is generally a convenience method which prevents your FTP server from getting
filled with lots of files; if you feel confident doing the cleanup by hand, the results 
will probably be better.

Caveat:  Don't call this function if you store anything else in the FTP directory
where the podcast and associated MP3 files are stored.  The module tries to be careful
about deleting what it knows about, but this is an asynchronous process.

=cut

sub enable_cleanup {
    my $self = shift;
    my $hash = shift;
    print "In enable cleanup.\n";
    if( $self->{ 'upload_handle' } ) {
	print "Setting cleanup to true\n";
	$self->{ 'upload_handle' }->set_cleanup( { 'clean' => 1,
						      ( $hash ? 
							( 'expires' => $hash->{ 'expires' } ) : 
							() ) } );
    }
}

=item disable_cleanup()

$podcast->disable_cleanup();

Disables cleanup of files.  See enable_cleanup().

=cut

sub disable_cleanup {
    my $self = shift;
    if( $self->{ 'upload_handle' } ) {
	$self->{ 'upload_handle' }->set_cleanup( { 'clean' => 0 } );
    }
    else {
	$self->error_message( "Cannot call enable cleanup until you have set_upload_settings()" );
    }
}

=item set_upload_settings()
    
$podcast->set_upload_settings( { ... } );
    
Creates a new FTP object which is used to upload RSS and MP3 files.  This method
accepts a hashref with the following keys:  host, username, password, path

=cut

sub set_upload_settings { 
    my $self = shift;
    # $self->log_message( "Entering set_upload_settings" );
    my $attr = shift;
    $self->{ 'upload_handle' } = Podcast::UploadManager->new();
    $self->{ 'upload_handle' }->init( $attr );
    $self->{ 'upload_handle' }->set_logger( $self->{ 'logger' } );
    $self->{ 'upload_handle' }->set_error_logger( $self->{ 'error_logger' } );
}

sub retrieve_items_by_statement
{
    my $self = shift;
    # $self->log_message( "Entering retrieve_item_by_statement" );
    my $statement = shift;
    my %items;
    $items{ 'error' } = 1;
    my $dbh = $self->get_dbh();
    eval { 
	if( $dbh ) {
	    my $sth = $dbh->prepare( $statement );
	    if( $sth ) {
		if( $sth->execute() ) {
		    # Success
		    $items{ 'error' } = 0;
		    if( $statement =~ /^select/ )  {
			my @info;
			while( my $ref = $sth->fetchrow_hashref() ) {
			    push @info, $ref;
			}
			$items{ 'items' } = \@info;
			$items{ 'items_count' } = scalar @info;
		    } # Don't need to do anything unless it is a select statement
		}
		else {
		    $items{ 'errstr' } = 
			"Cannot execute statement [$statement]";
		}
	    }
	    else {
		$items{ 'errstr' } = "Cannot prepare statement handle.";
	    }
	}
	else {
	    $items{ 'errstr' } = "Cannot access database";
	}
    };
    if( $@ ) { $items{ 'errstr' } = $@; }
    
    return { %items };
}

sub verify_episode_table {
    my $self = shift;
    my $dbh = shift;

    eval{
	$dbh->do( "select title from episodes limit 1" ) 
	    or die 1;
	};

    if( $@ ) {
	eval { 
	    $self->log_message( "Creating table in database ($@)" );
	    # Create it.
	    my $sql = <<"END";
		CREATE TABLE `episodes` 
		( `id` int(11) NOT NULL auto_increment,
		  `title` varchar(255) NOT NULL default '',
		  `link` varchar(255) default NULL,
		  `author` varchar(255) default NULL,
		  `category` varchar(64) default NULL,
		  `pubDate` int( 11 ) default NULL,
		  `mp3` varchar(255) NOT NULL default '',
		  `enabled` varchar(32) NOT NULL default 'yes',
		  `description` varchar(255) default NULL,
		  PRIMARY KEY  (`id`)
		  );
END
	    
             $dbh->do( $sql );
	    
	};
	if( $@ ) {
	    $self->log_error( "Cannot create table in database $@" );
	}
    }
}

sub get_dbh 
{
    my $self = shift;
    # $self->log_message( "Entering get_dbh" );
    my $dbh;
    if( $self->{ 'dbh' } ) {
	$dbh = $self->{ 'dbh' };
    }
    else { 
	eval {
	    my( $dsn, $username, $password );
	    $dsn = $self->{ 'db_dsn' };
	    $username = $self->{ 'db_username' };
	    $password = $self->{ 'db_password' };
	    $dbh = DBI->connect( $dsn, $username, $password );
	    # Make the table, if not there
	    $self->verify_episode_table( $dbh );
	};
	if( $@ ) {
	    $self->log_error( "Unable to establish DB connection: $@" );
	}
	else {
	    $self->{ 'dbh' } = $dbh if $dbh;
	}
    }
    return $dbh;
}

=item set_timezoe()

$podcast->set_timezone( 'PST' )

Set the timezone.  This is used when generating timestamps for the podcast RSS file.
Thurs 2005/06/23 12:34:56 GMT, for example.  GMT is used if this is unset.

=cut

sub set_timezone { 
    my $self = shift;
    my $timezone = shift;
    $self->log_message( "set_timezone: $timezone" );
    $self->{ 'timezone' } = $timezone if $timezone;
}

=item get_episodes()

$podcast->get_episodes();

Retrieve all the episodes as a bunch of hashrefs.  If you want to iterate
over each of the items and retrieve data you can do so with this method.

# This prints the title of the first episode,
 print $podcast->get_episodes()->[ 0 ]->{ 'title' };

=cut

sub get_episodes { 
    my $self = shift;
    # $self->log_message( "Entering get_episodes" );
    my $modifiers = shift;
    my $show_hidden;
    if( $modifiers ) {
	$show_hidden = $modifiers->{ 'view_hidden' };
    }
    my $timezone = $self->{ 'timezone' } || 'GMT';
    $self->log_error( "No DB connection string specified" ) unless $self->{ 'dbh' };
    my $limit = $self->{ 'maximum_episodes' } || 15;
    my $sql = "select * " .
	" from episodes " .
	( $show_hidden ? "" : " where enabled = 'yes' " ) .
	" order by id desc limit $limit";
    my $rh = $self->retrieve_items_by_statement( $sql );
    my $items = $rh->{ 'items' } if( $rh and !$rh->{ 'error' } );
    return $items;
}


=item set_episode_upload_metadata()

$podcast->set_episode_upload_metadata( index, metadata );

This sets the first episode to upload to podcasthosting.com with username/password "username" and "password" 
and put the files into "mypodcast/directory/path"

$podcast->set_episode_upload_metadata( 0, { 'protocol' => 'ftp', 'host' => 'podcasthosting.com', 
					    'username' => 'username', 'password' => 'password',
					    'path' => 'mypodcast/directory/path' } );

=cut

sub set_episode_upload_metadata { 
    my $self = shift;
    my $index = shift;
    my $info = shift;
    $_upload_info = [] unless $_upload_info;
    $_upload_info[ $index ] = $info;
}

=item delete_episode()

    $podcast->delete_episode( 1 );

This method deletes the episode from the podcast, and updates the RSS.
You provide the episode ID.

=cut

sub delete_episode { 
    my $self = shift;
    my $id = shift;
    $self->log_error( "Must specify id for deletion" ) unless $id;

    if( $id ) {
	$self->log_message( "Deleted episode with id $id" );
	my $sql = "delete from episodes where id = ?";
	my $sth = $self->get_dbh()->prepare( $sql );
	$sth->execute( $id );
	$self->write();
    }
}

=item hide_episode()

    $podcast->hide_episode( 1 );

This method hides the episode from view, removing it from the podcast RSS.  It does not
delete it from the database.

=cut

sub hide_episode { 
    my $self = shift;
    my $id = shift;
    if( $id ) {
	$self->log_message( "Hiding episode with id $id" );
	$self->change_episode_display( $id, 'no' );
    }
    else {
	$self->log_error( "No ID specified for hide_episode" );
    }

}

=item unhide_episode()

    $podcast->unhide_episode( 1 );

The opposite of hide_episode; adds the episode to the RSS.

=cut

sub unhide_episode { 
    my $self = shift;
    my $id = shift;
    if( $id ) {
	$self->log_message( "Hiding episode with id $id" );
	$self->change_episode_display( $id, 'yes' );
    }
    else {
	$self->log_error( "No ID specified for unhide_episode" );
    }
} 

sub change_episode_display { 
    my $self = shift;
    my $id = shift;
    my $display = shift;
    $self->log_error( "Must specify id for hiding" ) unless $id;
    my $sql = "update episodes set enabled = ? where id = ?";
    my $sth = $self->get_dbh()->prepare( $sql );
    $sth->execute( $display, $id );
    $self->write();
}

=item get_metadata()

    $podcast->get_metadata();

Returns metadata about the podcast feed as a hashref

=cut

sub get_metadata { 
    my $self = shift;
    # $self->log_message( "Entering get_metadata" );
    my $conf = $self->{ 'profile' } || $DEFAULT_CONF;
    my $ref = XMLin( $conf );
    return $ref;
}

=item set_profile()

    $podcast->set_profile( "./main.xml" );

Profiles can be used to store metadata for retrieval later.  First, call set_profile with 
a filename, and then call set_metadata with metadata.  The next time you can simply call 
set_profile to retrieve those settings.

=cut

sub set_profile { 
    my $self = shift;
    # $self->log_message( "Entering set_profile" );
    my $profile = shift;
    $self->{ 'profile' } = $profile;
}

=item set_metadata() 

    $podcast->set_metadata( { ... } );

Sets metadata, and writes it to a configuration file for later retrieval.  If you have 
not first called set_profile(), a default profile is used.  

Use the following keys: title, description, language, docs, editor, webmaster, 
generator.  pubDate and lastBuildDate are optional; if you leave them out
you'll get the date right now.  This metadata is placed in the header of the RSS file.  

=cut 

sub set_metadata { 
    my $self = shift;
    $self->log_message( "Setting metadata on podcast" );
    my $metadata = shift;
    my $conf = $self->{ 'profile' } || $DEFAULT_CONF;
    # croak "Conf $conf";
    my $xml = XMLout( $metadata );
    
    $fh = new IO::File ">$conf";
    if (defined $fh) {
	print $fh $xml;
	$fh->close;
	$self->log_message( "Wrote metadata to profile [$conf]" );
    }
    else {
	$self->log_error( "Cannot write $conf file for profile settings" );
    }
}

sub get_timezone { 
    my $self = shift;
    return $self->{ 'timezone' } || 'GMT';
}

=item write()

    $podcast->write();

Write out the RSS file.  You should call set_file() first to establish an RSS filename.

=cut

sub write { 
    my $self = shift;
    $self->log_message( "Writing podcast file" );
    my $filename = shift || $self->{ 'filename' };
    my $attr = $self->get_metadata();
    my $items = $self->get_episodes();
    
    my $title = $attr->{ 'title' };
    my $description = $attr->{ 'description' };
    my $language = $attr->{ 'language' } || 'en-us';
    my $timezone = $self->get_timezone();
    my $now = time();
    my $date = time2str( "%a, %d %h %Y %X $timezone", 
			 ( $attr->{ 'date' } || $now ) );
    my $build_date = 
	time2str( "%a, %d %h %Y %X $timezone",  
		  ( $attr->{ 'build_date' } || $attr->{ 'date' } || $now ) );
    my $docs = $attr->{ 'docs' };
    my $editor = $attr->{ 'editor' };
    my $webmaster = $attr->{ 'webmaster' };
    my $generator = $attr->{ 'generator' } || 'Webcast in a Box, Inc.';
    my $guid_reference = $attr->{ 'guid_base' };
    my $link = $attr->{ 'link' };

    $self->log_message( "Metadata: $title, $description, $timezone, $language, $date, $build_date, $doc, $editor, $webmaster, $generator" );

    my $last_build_date = time2str( "%a, %d %h %Y %X $timezone",  time );
    my %mapping = (
		   'title' => $title,
		   'description' => $description,
		   'language' => $language,
		   'pubDate' => $date,
		   'link' => $link,
		   'lastBuildDate' => $build_date,
		   'docs' => $docs,
		   'managingEditor' => $editor,
		   'webMaster' => $webmaster,
		   'generator' => $generator,
		   'lastBuildDate' => $last_build_date,
	       );

    my $output = new IO::File( ">" . $filename );
    $self->log_error( "Cannot open file: $filename" ) unless $output;
    my $blog = "http://backend.userland.com/blogChannelModule";
    my $writer = new XML::Writer( OUTPUT => $output, 
				  DATA_INDENT => 1,
				  DATA_MODE => 1,
				  );
    $writer->startTag( "rss",
		       # "xmlns:blogChannel" => $blog,
		       "version" => "2.0" );
    $writer->startTag( "channel" );
    foreach my $key ( 'title', 'link', 'description', 'language',
		      'pubDate', 'lastBuildDate', 'docs',
		      'generator', 'managingEditor', 'webMaster' ) {
	$writer->dataElement( $key, $mapping{ $key } );
    }
    
    if( $items ) {
	foreach my $item ( @{$items} ) {

	    # Generate the items first; if there are errors, 
	    # abort this item
	    # Add the enclosure
	    my $length = $self->get_length( $item->{ 'mp3' } );
	    my $file_url = $self->compose_url( $item->{ 'mp3' } );
	    my $guid = $guid_reference . $file_url;

	    $item->{ 'link' } = $guid;
	    $item->{ 'pubDate' } = time2str( "%a, %d %h %Y %X $timezone",  
					     $item->{ 'pubDate' } );

	    if( $length and $file_url ) {
		$writer->startTag( "item" );
		foreach my $key ( 'title', 'link', 'category', 'author',
				  'description', 'pubDate' ) {
		    $writer->dataElement( $key => $item->{ $key } );
		    $self->log_message( "Item data: ". $key . " => " .  $item->{ $key } );
		}
		
		# Add the guid item
		$writer->startTag( "guid" ); # , "isPermaLink" => "false" );
		$writer->characters( $guid );
		$writer->endTag( "guid" );
		
		$self->log_message( "Enclosure data: $file_url with length: $length" );
		$writer->startTag( "enclosure", 
				   'length' => $length,
				   'url' => $file_url,
				   'type' => 'audio/mpeg' );
		$writer->endTag( "enclosure" );
		$writer->endTag( "item" );
	    }
	}
    }
    
    $writer->endTag();
    $writer->endTag();
    $writer->end();
    $output->close();
}

=item set_file()

    $podcast->set_file( $file );

Sets the filename to use when writing the RSS file.

=cut

sub set_file { 
    my $self = shift;
    # $self->log_message( "Entering set_file" );
    $self->{ 'filename' } = shift;
}

=item set_db_connectio()

$podcast->set_db_connection( { .. } )

Set the database settings.  You should provide these keys: dsn, username, password
The dsn will be one of the standard DBD::* drivers, like mysql and the appropriate 
connection information.

Examples:
DBI:mysql:podcast=;host=localhost

=cut

sub set_db_connection { 
    my $self = shift;
    my $args = shift;

    # Nice to support this at some point: DBI:CSV:f_dir=/home/joe/csvdb
    # $self->log_message( "Entering set_db_connection" );
    $self->{ 'db_dsn' } = $args->{ 'dsn' };
    $self->{ 'db_username' } = $args->{ 'username' };
    $self->{ 'db_password' } = $args->{ 'password' };
    $self->get_dbh();
}

=item add_new_episode()

    $podcast->add_new_episode( { .. } );

Adds a new episode to the podcast RSS feed, and optionally updates metadata in the associated file
to synchronize with the database information, if the synchronize flag is set.  Use the following keys 
in the hashref provided: title, author, category, pubDate, description, mp3

=cut

sub add_new_episode { 
    my $self = shift;
    $self->log_message( "Entering add_new_episode" );
    my $item = shift;
    my $no_update = shift;
    $self->write_episode_metadata( $item );
    $self->write() unless $no_update;
}

=item get_titles()

    $arrayref= $podcast->get_titles();

Convenience method to get all titles as an array ref.

=cut 

sub get_titles { 
    my $self = shift;
    $self->log_message( "Entering get_titles" );

    # Get the items, and grab the titles
    my $items = $self->get_episodes();
    if( $items ) {
	foreach my $item ( @{$items} ) {
	    push @titles, $item->{ 'title' };
	}
    }
    return \@titles;
}

sub verify_item_contents {
    my $item = shift;
    foreach my $required ( 'title' ) { 
	$self->log_error( "Need a $required" ) unless $item->{ $required };
    }
}

sub get_filename { 
    my $self = shift;
    return $self->get_file( @_ );
}

sub get_file { 
    my $self = shift;
    $self->log_message( "Entering get_file" );
    my $id = shift;
    my $sql = "select * from episodes where id = ?";
    my $sth = $self->get_dbh()->prepare( $sql );
    $sth->execute( $id );
    my $file;
    if( my $item = $sth->fetchrow_hashref() ) {
	$file = $item->{ 'mp3' };
    }
    return $file;
}

=item update_episode()

    $podcast->update_episode( { .. } );

Updates episode data.  Provide the same hash ref as in add_new_episode but you must also
provide a value for the key 'id' which is the numeric key to the episode to edit.

=cut

sub update_episode { 
    my $self = shift;
    $self->log_message( "Entering update_episode" );

    my $item = shift;
    $self->log_error( "Provide a hash ref with item values" )
	unless $item;

    my $index = $item->{ 'id' } || $item->{ 'insert_id' };
    $self->log_error( "Need to declare the insertion point with " . 
	    "index/insert_index in the hash ref" )
	unless defined $index and $index >= 0;

    &verify_item_contents( $item );
    $self->write_episode_metadata( $item );
    $self->write();

}

sub write_episode_metadata { 
    my $self = shift;
    $self->log_message( "Entering write_episode_metadata" );
    my $item = shift;

    my $id = $item->{ 'id' };
    my $date = $item->{ 'pubDate' };
    $date = $item->{ 'date' } unless $date;
    $date = time() unless $date;
    # Get the year from the time
    my $year = time2str( "%Y", $date );

    my $title = $item->{ 'title' };
    my $creator = $item->{ 'author' } || $item->{ 'artist' };
    my $album = $item->{ 'album' };
    my $description = $item->{ 'description' };
    my $podcast = $item->{ 'associated_podcast' };
    my $category = $item->{ 'category' } || $item->{ 'genre' };
    my $link = $item->{ 'link' };
    chomp $date;
    my $sql;
    my @values;

    $item->{ 'title' } = $title;
    $item->{ 'author' } = $author;
    $item->{ 'category' } = $category;
    $item->{ 'pubDate' } = $date;
    $item->{ 'associated_podcast' } = $podcast;
    $item->{ 'description' } = $description;
    my $file = $item->{ 'mp3' };

    $self->log_message( "Episode data: $title, $author, $category, $date, $description, $file, $podcast" );

    if( $id ) {
	my @potentials = ( 'title',
			   'link',
			   'author',
			   'category',
			   'pubDate',
			   'description',
			   'associated_podcast',
			   'mp3' );
	$sql = "update episodes set ";
	my @code;
	foreach my $potential ( @potentials ) {
	    if( $item->{ $potential } ) {
		push @code, ( $potential . " = ?" );
		$self->log_message( "Episode datum: " . $item->{ 'potential' } );
		push @values, $item->{ $potential };
	    }
	}
	$sql .= ( join ", ", @code );
	$sql .= " where id = ?";
	push @values, $id;
    }
    else {
	$sql = "insert into episodes " .
	    "       ( title, link, author, category, pubDate, description, mp3, associated_podcast ) " .
	    " values( ?,     ?,    ?,      ?,        ?,       ?,           ?,   ? )";
	@values = ( $title,
		    $link,
		    $creator,
		    $category,
		    $date, 
		    $description,
		    $file,
		    $associated_podcast );
    }

    $self->log_message( "SQL: $sql, Values: @values" );
    my $sth = $self->{ 'dbh' }->prepare( $sql );
    $sth->execute( @values );
    $self->log_message( "Error: " . $sth->errstr );
    $file = $self->get_file( $id ) unless $file; 
    my $full_file = -e $file ? $file : ( $self->{ 'local_root' } . $file );  
	
    # Update the mp3 as well
    if( $self->{ 'synchronize' } ) {
	use MP3::Info;

	my @mp3_data = ( $full_file, 
			 $title, $creator, $album, 
			 $year, $description, $category );
	if( !set_mp3tag ( @mp3_data ) ) {

	    $self->log_error( "Cannot write using MP3::Info, trying with mp3info" );
	    # Try with mp3info
	    # mp3info [-i] [-t title] [-a artist] [-l album] [-y year] 
	    # [-c comment] [-n track] [-g genre] file...
	    if( 0 != system( "mp3info",
			     "-t", $title,
			     "-a", $author,
			     "-l", $album,
			     "-c", $description,
			     "-g", $category,
			     $full_file ) ) {
		$self->log_error( "Cannot set mp3 information for $full_file" );
	    }
	    else {
		$self->log_message( "Set mp3 data with mp3info: @mp3_data" );
	    }
	}
	else {
	    $self->log_message( "Set mp3 data with set_mp3tag: @mp3_data" );
	}
    }
}

sub set_verbose { 
    my $self = shift;
    $self->log_message( "Entering set_verbose" );
    $self->{ 'verbose' } = shift; 
}


sub compose_url { 
    my $self = shift;
    $self->log_message( "Entering compose_url" );
    my $file = shift;
    
    # Strip off the front of the filename
    my $short = $1 
	if $file =~ /\/?([^\/]+)$/;
    $short = $file unless $short;
    my $msg= "Using short name: $short ($file)";
    # print $msg;
    $self->log_message( $msg );
    return $self->{ 'remote_root' } . $short;
}

=item set_remote_root()

    $podcast->set_remote_root( "http://foobar.com/podcasts/" );

Set the remote root for the podcasts RSS.  Items which are uploaded will be references
with this URL as the base.  

=cut

sub set_remote_root { 
    my $self = shift;
    # $self->log_message( "Entering set_remote_root" );
    $self->{ 'remote_root' } = shift;
}

=item set_local_root()

    $podcast->set_local_root( "/home/foobar/podcasts/episodes" );

Set this if you provide only relative pathnames to your episode MP3 files
and not the fully specified paths.  If you do this, all MP3s should be in the same
directory.

=cut 
sub set_local_root { 
    my $self = shift;
    # $self->log_message( "Entering set_local_root" );
    $self->{ 'local_root' } = shift;
    $self->{ 'local_root' } .= "/" 
	unless $self->{ 'local_root' } =~ /\/$/;
}

sub get_length { 
    my $self = shift;
    my $file = shift;
    my $length;
    # Does file exist as is?
    if( -e $file ) {
	$length = -s $file;
    }
    elsif( -e $self->{ 'local_root' } . $file ) {
	$length = -s $self->{ 'local_root' } . $file;
    }
    
    # TODO:  Add code to resolve remote filesize

    return $length;
}

=item set_maximum_episodes()

    $podcast->set_maximum_episodes( 20 );

By default the RSS generated will use the last 15 episodes.  If you wish to use more or less
than this, set the value here.  

=cut 

sub set_maximum_episodes { 
    my $self = shift;
    $self->log_message( "Entering set_maximum_episodes" );
    $self->{ 'maximum_episodes' } = shift;
}

=item set_synchronize()

    $podcast->set_synchronize()

    Synchronize changes to the MP3 with changes to the database

=cut 
sub set_synchronize {
    my $self = shift;
    $self->{ 'synchronize' } = shift;
}

sub set_uploaded_status {
    my $self = shift;
    my $item = shift;
    my $value = shift;

    # If item is not an episode, get it
    if( 'HASH' ne ref $item ) {
	$item =~ s/'/\\'/g;
	my $sql = "select * from episodes where id = '$item'";
	my $rh = $self->retrieve_items_by_statement( $sql );
	my $items = $rh->{ 'items' } if( $rh and !$rh->{ 'error' } );
	$item = $items->[ 0 ];
    }

    $value = 1 unless defined $value;
    eval {
	# Store the flag in the database
	my $sql = "update episodes set uploaded = ? where id = ?";
	my $sth = $self->{ 'dbh' }->prepare( $sql );
	$sth->execute( $value, $item->{ 'id' } );
    };
    if( $@ ) {
	$self->error_message( "FATAL: Unable to set episodes uploaded status field" );
    }
}

1;

