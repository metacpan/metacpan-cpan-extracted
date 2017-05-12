package MusicRoom::Lyrics;

use strict;
use warnings;
use Carp;

use MP3::Tag;
use MusicRoom::File;
use MusicRoom::Track;
use MusicRoom::Locate;

use constant LYRICS_LOCATOR => "lyrics";

my $configured;

sub init
  {
    # If we already have loaded the directory details then we can 
    # just move on

    return if(defined $configured);
    MusicRoom::Locate::scan_dir(LYRICS_LOCATOR);
    $configured = 1;
  }

sub locate
  {
    my($track) = @_;

    init();
    return MusicRoom::Locate::locate($track,LYRICS_LOCATOR);
  }

sub search_for
  {
    my($track) = @_;

    init();
    return MusicRoom::Locate::search_for($track,LYRICS_LOCATOR);
  }

1;


