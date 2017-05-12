package MusicRoom::CoverArt;

=head1 NAME

MusicRoom::CoverArt - Identify suitable cover images for tracks

=head1 DESCRIPTION

This package scans a directory full of images to identify a suitable 
image for a nominated music track.  The software is configured by a 
specification file that tells it where to find images.  Here is an 
example specification file:

    # Look for the ID, then the artist and finally use a default
    by_id/<id>.jpg
    by_artist/<artist>.jpg
    default.jpg

In the function calls the $track argument is assumed 
to contain a reference to a hash with values for all the attributes
that are mentioned in the specification file.

If the package is called like:

    use MusicRoom::CoverArt;

    my $t1 = {id => "tf6ty2", artist => "Paul Simon", 
               song => "That Was Your Mother",
               album => "Graceland"};

    my $jpg1_file = MusicRoom::CoverArt::locate($t1);

The specification file above causes the software to look for the files:

    /data/music/meta/art/by_id/tf6ty2.jpg
    /data/music/meta/art/by_artist/Paul Simon.jpg
    /data/music/meta/art/default.jpg

returning the name of the first one that is found or undefined if there 
are none of them.

A more reasonable specification file might look like:

    by_id/<id>.jpg
    by_dirartist/<dir_artist>/<artist> - <name>.jpg
    by_dir/<dir_name>.jpg
    by_artist/<artist>.jpg
    default.jpg

This tells the software to look for:

    1. The exact ID
    2. A combination of the artist associated with the directory, 
       the real artist and the track name.  This lets us specify 
       an image like "Various Artist/The Byrds - Mr Tambourine Man.jpg"
       which is used whenever that song is found on a Various Artist 
       collection
    3. An image that is named the same as the album directory
    4. An image of the artist
    5. A default image if none of the above are available

    my $t1 = {id => "tf6ty2", track => "10", length => "02:51", 
               artist => "Paul Simon", song => "That Was Your Mother",
               album => "Graceland", dir_artist => "Paul Simon",
               dir_album => "Graceland", dir_name => "Paul Simon - Graceland",
               size => "1371741", quality => "7", year => "1986"};
    my $t2 = {id => "8nj3vp", track => "06", length => "03:16",
               artist => "The Clash", song => "Tommy Gun", 
               album => "The Singles", dir_artist => "The Clash",
               dir_album => "The Singles", dir_name => "The Clash - The Singles",
               size => "1575705",quality => "7",year => "1978"};
=cut

use strict;
use warnings;
use Carp;

use MP3::Tag;
use MusicRoom::File;
use MusicRoom::Track;
use MusicRoom::Locate;

use constant COVERART_LOCATOR => "coverart";
use constant PICTURE_TYPE => "Cover (front)";
use constant PICTURE_COMMENT => "Cover Image";
use constant APIC => "APIC";

my $configured;

sub init
  {
    # If we already have loaded the directory details then we can 
    # just move on

    return if(defined $configured);
    MusicRoom::Locate::scan_dir(COVERART_LOCATOR);
    $configured = 1;
  }

sub locate
  {
    my($track) = @_;

    init();
    return MusicRoom::Locate::locate($track,COVERART_LOCATOR);
  }

sub search_for
  {
    my($track) = @_;

    init();
    return MusicRoom::Locate::search_for($track,COVERART_LOCATOR);
  }

sub attach
  {
    # Find a suitable image and attach it to the suggested mp3 file
    my($track,$mp3_file) = @_;

    my $image_file = locate($track);
    return undef
         if(!defined $image_file);

    if(!-w $mp3_file)
      {
        # This shouldn't happen but...
        chmod 0755,$mp3_file;
      }
    if(!-w $mp3_file)
      {
        carp("Cannot write to $mp3_file");
        return undef;
      }
    my $mp3 = MP3::Tag->new($mp3_file);

    if(!defined $mp3)
      {
        carp("Cannot read tags from $mp3_file");
        return undef;
      }

    # Attempt to read the tags
    $mp3->get_tags();
    if(!defined $mp3->{ID3v2})
      {
        # Need to create a new set of tags
        $mp3->new_tag("ID3v2");
      }

    if(!defined $mp3->{ID3v2})
      {
        carp("Cannot create ID3v2 tags in $mp3_file");
        return undef;
      }

    my($mime_type,$image_data) = read_image($image_file);
    return undef if(!defined $mime_type);

    my $encoding = 0;
    my @apic_parts = ($encoding, $mime_type,
             picture_type_idx(PICTURE_TYPE),
             PICTURE_COMMENT, $image_data);

    if(defined $mp3->{ID3v2}->get_frame(APIC))
      {
        # Modifying an existing image
        $mp3->{ID3v2}->change_frame(APIC,@apic_parts);
      }
    else
      {
        # Create a new frame
        $mp3->{ID3v2}->add_frame(APIC,@apic_parts);
      }
    $mp3->{ID3v2}->write_tag();
    return $image_file;
  }

sub read_image
  {
    # Read the image file
    my($file_name) = @_;

    my $image_type;
    my $image_data;

    if(!-f $file_name)
      {
        error("Cannot read file \"$file_name\"");
        return;
      }

    if($file_name =~ /\.jpg$/i)
      {
        $image_type = "jpg";
        my $ifh = IO::File->new($file_name);
        if(!defined $ifh)
          {
            error("Failed to open \"$file_name\"");
            return;
          }
        binmode $ifh;

        $image_data = "";

        # This reads the data in 16k chunks, but the images should be small anyway

        while(!$ifh->eof())
          {
            my $c = $ifh->read($image_data,1024*16,length($image_data));
          }
        $ifh = undef;
      }

    if(!defined $image_type)
      {
        error("Does not yet support file type for \"$file_name\"");
        return;
      }
    if(!defined $image_data)
      {
        error("Cannot extract $image_type data from \"$file_name\"");
        return;
      }

    return("image/$image_type",$image_data);
  }

sub picture_type_idx
  {
    # Given a picture type string convert it into a number suitable
    # for MP3::Tag
    my($picture_type) = @_;

    # The picture types that are currently understood (from MP3::Tag::ID3v2):
    my @picture_types =
         ("Other", "32x32 pixels 'file icon' (PNG only)", "Other file icon",
           "Cover (front)", "Cover (back)", "Leaflet page",
           "Media (e.g. lable side of CD)", "Lead artist/lead performer/soloist"
,
           "Artist/performer", "Conductor", "Band/Orchestra", "Composer",
           "Lyricist/text writer", "Recording Location", "During recording",
           "During performance", "Movie/video screen capture",
           "A bright coloured fish", "Illustration", "Band/artist logotype",
           "Publisher/Studio logotype");

    # This approach is easy to understand
    for(my $i=0;$i<=$#picture_types;$i++)
      {
        if(lc($picture_type) eq lc($picture_types[$i]))
          {
            return chr($i);
          }
      }
    error("The picture type \"$picture_type\" is not valid");
    return chr(3);
  }

1;
