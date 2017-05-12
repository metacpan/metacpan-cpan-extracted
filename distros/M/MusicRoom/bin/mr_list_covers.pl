# Create a summary list (in CSV format) of which jpg files will
# get attached to each mp3 listed in a CSV file
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

my %tracks;

# The columns to report
my @columns = 
  (
    "id", "artist", "title", "album", 
    "dir_artist", "dir_album","art_file", "search_list",
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

# Report the results to a CSV file
my $target_file = MusicRoom::File::new_name("coverart","csv");
my $ofh = IO::File->new(">$target_file");
if(!defined $ofh)
  {
    print STDERR "Failed to open $target_file for writing";
    exit 20;
  }

my $art_dir;

print $ofh join(",",@columns)."\n";
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

$ofh->close();

exit 0;

sub process_track
  {
    my($track) = @_;
    foreach my $attr (@columns)
      {
        my $val;
        if($attr eq "art_file")
          {
            $val = MusicRoom::CoverArt::locate($track);
            # Cannot find the dir until after we have looked for our 
            # first cover
            $art_dir = MusicRoom::Locate::dir_of("coverart")
                          if(!defined $art_dir);
            $val =~ s/^$art_dir// if(defined $val);
          }
        elsif($attr eq "search_list")
          {
            my @vals = MusicRoom::CoverArt::search_for($track);
            $val = join(', ',@vals);
          }
        elsif(defined $track->{$attr})
          {
            $val = $track->{$attr};
            if(ref($val))
              {
                $val = $val->name();
              }
          }
        else
          {
            $val = $track->get($attr);
            if(ref($val))
              {
                $val = $val->name();
              }
          }
        print $ofh "," if($attr ne "id");
        $val = "" if(!defined $val);
        print $ofh "\"$val\"";
      }
    print $ofh "\n";
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
