# Setup script that configures MusicRoom

use strict;
use warnings;
use MusicRoom;
use MusicRoom::InitialLists;
use Carp;

MusicRoom::configure();

# Now add the valid names of artists, songs and albums to the newly 
# created space if they are not already defined
my $musicroom_dir = MusicRoom::get_conf("dir");
foreach my $cat ("artist","album","song")
  {
    my $existing_file = MusicRoom::File::latest(
                        "valid-${cat}s",
                                     dir => ${musicroom_dir},
                                     quiet => 1,look_for => "txt");
    next if(defined $existing_file);

    # No valid file there yet, lets make one from the initial lists
    $existing_file = MusicRoom::File::new_name("${musicroom_dir}valid-${cat}s","txt");
    my $ofh = IO::File->new(">$existing_file");
    croak("Cannot open file \"$existing_file\" for writing")
                                                 if(!defined $ofh);
    print $ofh <<"EndHeader";
# Valid $cat file for MusicRoom.  This text file contains a list
# of the valid names for ${cat}s in this setup.  It was generated from
# the list of hits at http://tsort.info/ and includes all ${cat}s 
# that have more than one entry in the charts of the world.
#
# This file has been kept as a simple text file so you can edit it to 
# meet your needs
EndHeader
    foreach my $item (MusicRoom::InitialLists::list($cat))
      {
        print $ofh "$item\n";
      }
    $ofh->close();
  }

# Cleanly close all the databases
MusicRoom::shutdown_database();

