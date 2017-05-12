# Find all the songs that include any on of a 
# list of words in the lyrics
use strict;
use warnings;

BEGIN
  {
    foreach my $dir ('../lib','lib','.')
      {
        unshift @INC,$dir if(-d $dir);
      }
  }

use IO::File;
use Carp;

use MusicRoom;
use MusicRoom::Lyrics;

my @words = @ARGV;
if($#words < 0)
  {
    croak("Must supply a list of words to look for");
  }

my %tracks;

# The columns to report
my @columns = 
  (
    "id", "artist", "title", "album", 
    "dir_artist", "dir_album", "lyrics_file", "search_list",
  );
# my $source = "db";
my $source = "D:/mydata/music/flaccer";

if($source ne "db")
  {
    # We are reading from a csv file in the flaccer dir
    my @files =
      (
        "src-tracks" => \&do_src_tracks,
        "src-id2carry" => \&do_src_id2carry,
        "src-id2best" => \&do_src_id2best,
      );
    for(my $i=0;$i<=$#files;$i+=2)
      {
        my $src_file = MusicRoom::File::latest($files[$i],
                                     dir => $source,look_for => "csv",quiet => 1);
        if(!defined $src_file)
          {
            croak("Cannot find \"$files[$i]\" in $source");
          }
        my $ifh = IO::File->new($src_file);
        if(!defined $ifh)
          {
            croak("Cannot open file \"$src_file\" in $source");
          }
        MusicRoom::Text::CSV::scan($ifh,action => $files[$i+1]);
        $ifh->close();
      }
  }

# Report the results
my $art_dir;

if($source eq "db")
  {
    foreach my $track (MusicRoom::Track::select_objects())
      {
        process_track($track);
      }
  }
else
  {
    foreach my $track_id (list_ids())
      {
        process_track(data_for_id($track_id));
      }
  }

exit 0;

sub process_track
  {
    my($track) = @_;

    my $file_name = MusicRoom::Lyrics::locate($track);
    # If we have no lyrics then just step past this one
    return if(!defined $file_name);

    # Cannot find the dir until after we have looked for our 
    # first set of lyrics
    $art_dir = MusicRoom::Locate::dir_of("lyrics")
                          if(!defined $art_dir);

    # Look to see if the file contains the word being looked for
    my $lyric_fh = IO::File->new($file_name);
    if(!defined $lyric_fh)
      {
        carp("Cannot open file \"$file_name\"");
        return;
      }
    my $contents = join("\n",<$lyric_fh>);
    $lyric_fh->close();
    foreach my $word (@words)
      {
        if($word =~ /^m#/)
          {
            # This is a pattern rather than a word
            if(eval("\$contents =~ $word"))
              {
                send_report($track);
              }
          }
        elsif($contents =~ m#$word#i)
          {
            send_report($track);
          }
      }
  }

sub send_report
  {
    my($track) = @_;

    print "$track->{id}|$track->{artist}|$track->{title}\n";
  }

{
my %all_tracks;
my @id_order;

sub do_src_tracks
  {
    my(%attribs) = @_;
    if(!defined $attribs{id})
      {
        carp("Undefined ID in src-tracks");
      }
    if(defined $all_tracks{$attribs{id}})
      {
        carp("Multiple definitions for ID $attribs{id} in src-tracks");
      }
    $attribs{title} = $attribs{song};
    if($attribs{track} =~ /^\d+$/)
      {
        $attribs{track_num} = sprintf("%02d",$attribs{track});
      }
    elsif($attribs{track} =~ /^(\d+)/)
      {
        $attribs{track_num} = sprintf("%02d",$1);
      }
    else
      {
        carp("Cannot parse track number $attribs{track} from src-tracks $attribs{id}");
        $attribs{track_num} = $attribs{track};
      }

    if($attribs{length} =~ /^\d+$/)
      {
        $attribs{length_secs} = $attribs{length};
      }
    elsif($attribs{length} =~ /^(\d+)\:(\d+)$/)
      {
        $attribs{length_secs} = (60*$1)+$2;
      }
    elsif($attribs{length} =~ /^(\d+)\:(\d+)\:(\d+)$/)
      {
        $attribs{length_secs} = (60*(60*$1)+$2)+$3;
      }
    else
      {
        carp("Cannot parse length $attribs{length} from src-tracks $attribs{id}");
        $attribs{length_secs} = 0;
      }

    $attribs{_have_carry} = "";
    $all_tracks{$attribs{id}} = \%attribs;
    push @id_order,$attribs{id};
  }

sub do_src_id2carry
  {
    my(%attribs) = @_;
    if(!defined $attribs{id})
      {
        carp("Undefined ID in src-id2carry");
      }
    if(!defined $all_tracks{$attribs{id}})
      {
        carp("Cannot find id2carry ID $attribs{id} in src-tracks");
      }
    $all_tracks{$attribs{id}}->{_have_carry} = 1;
  }

sub do_src_id2best
  {
    my(%attribs) = @_;
    if(!defined $attribs{id})
      {
        carp("Undefined ID in src-id2best");
      }
    if(!defined $all_tracks{$attribs{id}})
      {
        carp("Cannot find id2best ID $attribs{id} in src-tracks");
      }
    if($attribs{bestbasename} =~ m#^\./+([^/]+)/+([^/]+)$#)
      {
        ($attribs{bestbasedir},$attribs{bestbasefile}) = ($1,$2);
      }
    else
      {
        carp("Cannot pick directory and file from \"$attribs{bestbasename}\"");
      }
    $attribs{original_format} = $attribs{bestformat};

    foreach my $key (keys %attribs)
      {
        if(!defined $all_tracks{$attribs{id}}->{$key})
          {
            $all_tracks{$attribs{id}}->{$key} = $attribs{$key};
          }
      }
  }

sub list_ids
  {
    return @id_order;
  }

sub data_for_id
  {
    my($id) = @_;

    croak("Must supply ID to data_for_id") if(!defined $id || $id eq "");
    if(!defined $all_tracks{$id})
      {
        carp("Undefined id \"$id\"");
        return undef;
      }
    return $all_tracks{$id};
  }
}
