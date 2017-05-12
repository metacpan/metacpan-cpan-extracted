#!/usr/bin/perl

use Podcast::Publisher;

my $podcast = Podcast::Publisher->new;
$podcast->set_logger( sub { my $msg = shift; print $msg . "\n"; } );
$podcast->set_error_logger( sub { my $msg = shift; print "ERROR: $msg\n" } );

my $xml = "podcast.xml";

# Add all the items from the database
$podcast->set_remote_root( "http://localhost/podcast/publishing/chris/" );
# if all files will be in the same directory, otherwise 
# specify full paths to each mp3.
$podcast->set_local_root( "./items" );
# Set the DB connection.
$podcast->set_db_connection( { 'dsn' => "DBI:mysql:podcast;host=localhost",
			       'username' => 'poduser',
			       'password' => 'podpass' } );
$podcast->set_file( $xml );
$podcast->set_profile( "main.xml" );

# Set this once.  The next time you run the script, set_profile will
# load these settings for you without a call to set_metadata
$podcast->set_metadata( { 'title' => "Chris Podcast",
			  'description' => "All About Chris",
			  "docs" => "http://webiphany.com",
			  "editor" => "chris\@localhost",
			  "webmaster" => "chris\@localhost",
		      } );

my $episodes = $podcast->get_episodes();
print "Count is " . scalar( @{$episodes} );
my $id = $episodes->[ 0 ]->{ 'id' };
if( $id ) {
    $podcast->delete_episode( $id );
    print "Deleted episode $id\n";
}
$episodes = $podcast->get_episodes();
print "Count is " . scalar( @{$episodes} );

$podcast->add_new_episode( {
    'title' => 'Chris new test',
    'description', 'Something simple',
    'mp3' =>  './sample.mp3'
    } );
$podcast->write();
$podcast->set_upload_settings( { 'host' => 'localhost',
				 'username' => 'test',
				 'password' => 'test',
				 'path' => 'podcast/publishing/chris',
				 'remote_root' => 'http://localhost/chris/' } );
# $podcast->upload();

my $titles = $podcast->get_titles();
foreach my $title ( @{$titles} ) {
    print "TITLE: $title\n";
}

print "Size: " . scalar( @{$podcast->get_items()} ) . "\n";
