#!/bin/env perl

# Given that we already have a best source (somewhere on a data DVD) this program will
# Resample the source to the carry data

# We scan src-tracks and src-id2carry to find ids that are in the track listing 
# but not on the carry one (every time we need a resample, for example because 
# a track has been mislabaled we have to redo the carry data anyway)

use strict;
use warnings;

use Carp;
use MusicRoom;
use IO::File;
use File::Copy;
use Win32::File;

# This spec must only use / as a seperator and cannot either 
# start or end in a /
my $best_dir_spec = "<dir_artist> - <dir_album>";
my $best_file_spec = "<artist> - <title>";
my $active_format = "mp3:128";
my $scratch_dir = "build_tmp";
my $perdir_listing = "tracks";
my @required_columns = 
  (
    "id","artist","title","album","dir_artist","dir_album",
    "track_num","length_secs","quality","original_format",
    "year","target_dir","target_file","original_ext",
  );

$| = 1;

# The places to look for source DVD data and the target directory (in order)
# of course this assumes we are on Windows
my @possible_disks = ("", "E:", "F:", "G:", "H:", "D:", "C:", 
                      # Could be that this is meant to get it from the 
                      # backups
                      "E:/mydata","F:/mydata");

# Modes are "none", "by_file", "by_dir", "dynamic"
my $normalise_mode = "dynamic";

my $flaccer_dir = "D:/mydata/music/flaccer";
my $active_target_dir = identify_dir("Target","music")."music";

# The various CSV files tell us what to do
my @resample_dirs = read_csvs();

if(!-d $scratch_dir)
  {
    make_dir($scratch_dir);
    croak("Cannot create directory $scratch_dir")
                                  if(!-d $scratch_dir);
  }
check_scratch_empty();

# We have two tasks per file, getting if from the best and 
# putting it into the active
my $num_files_to_copy = 2*(count_files(@resample_dirs));
my $num_files_copied = 0;

if($num_files_to_copy <= 0)
  {
    croak("Cannot find any files to resample, there are none missing from id2carry");
  }
# Work out the standard format we are going to use in the active area
my $working_format = MusicRoom::File::working_format();
my $working_ext = MusicRoom::File::formats_extension($working_format);
my $active_ext = MusicRoom::File::formats_extension($active_format);

my %dirs;
foreach my $dir (@resample_dirs)
  {
    croak("Directory without contentents!")
                             if(!defined $dir || $#{$dir} < 0);

    # Have to do some checking before we start any of the processing
    my $final_target_dir = MusicRoom::Locate::expand($dir->[0],$best_dir_spec);
    if(-d "$active_target_dir/$final_target_dir")
      {
        croak("Target dir $active_target_dir/$final_target_dir already exists, either delete or change src-tracks");
      }
    if(defined $dirs{$final_target_dir})
      {
        croak("Two conflicting dirs called $final_target_dir change src-tracks");
      }
    $dirs{$final_target_dir} = {};
    my %filename_to_id;

    foreach my $track (@{$dir})
      {
        # It is quite possible that we have two files called the same thing in a single dir 
        # so we cannot tell the user to try again if that happens
        my $orig_target_file = MusicRoom::Locate::expand($track,$best_file_spec);
        my $final_target_file = "$orig_target_file";
        my $count = 1;
        # As long as we have existing tracks with the same name keep moving
        while(defined $filename_to_id{$final_target_file})
          {
            $count++;
            $final_target_file = "$orig_target_file($count)";
          }
        $filename_to_id{$final_target_file} = $track->{id};
        $dirs{$final_target_dir}->{$track->{id}} = $final_target_file;
        $track->{final_filename} = $final_target_file;
        $track->{target_dir} = $final_target_dir;
        $track->{target_file} = $track->{final_filename};
      }
  }

foreach my $dir (@resample_dirs)
  {
    # OK where is the source for this?
    my $orig_dirbase = identify_dir($dir->[0]->{bestsrc},$dir->[0]->{bestbasedir});
    check_scratch_empty();
    my @temp_files = ();

    my $best_dir = $orig_dirbase.$dir->[0]->{bestbasedir};
    my $dir_start_time = cur_time();
    print "Started $dir_start_time \"$best_dir\"\n";
    progress("Converting Files",$num_files_copied,$num_files_to_copy);

    my $final_target_dir = MusicRoom::Locate::expand($dir->[0],$best_dir_spec);

    make_dir("$active_target_dir/$final_target_dir");
    if(!-d "$active_target_dir/$final_target_dir")
      {
        croak("Cannot make directory \"$active_target_dir/$final_target_dir\"");
      }
    my $dest_file = MusicRoom::File::new_name(
                             "$active_target_dir/$final_target_dir/$perdir_listing","csv");
    my $ofh = IO::File->new(">".$dest_file);
    
    if(!defined $ofh)
      {
        croak("Cannot open file $dest_file");
      }
    print $ofh join(',',@required_columns)."\n";

    my $normalise_guess = "by_dir";

    foreach my $track (@{$dir})
      {
        my $id = $track->{id};

        $track->{original_ext} = MusicRoom::File::formats_extension($track->{bestformat});

        my $full_src = "$best_dir/$track->{bestbasefile}\.".
                                  MusicRoom::File::formats_extension($track->{bestformat});
        my $full_work = "$scratch_dir/$track->{final_filename}\.$working_ext";

        progress("\nConverting Files",$num_files_copied++,$num_files_to_copy);
        print "\n";
        if(!MusicRoom::File::convert_audio($full_src,$track->{bestformat},
                                           $full_work,$working_format))
          {
            croak("Cannot convert $track->{bestformat} to $working_format");
          }
        if(!-r $full_work)
          {
            croak("Failed to convert to $full_work");
          }
        push @temp_files,"$track->{final_filename}\.$working_ext";

        # If the source is a DVD then typically the "READONLY" bit will be set,
        # so lets undo that before we normalise
        my $file_attribs;
        Win32::File::GetAttributes(dosify($full_work),$file_attribs);
        if($file_attribs & READONLY)
          {
            $file_attribs &= ~READONLY;
            Win32::File::SetAttributes(dosify($full_work),$file_attribs);
          }

        $normalise_guess = "by_song" if($track->{dir_artist} eq "Various Artists");
      }
    if($normalise_mode eq "by_dir" || $normalise_mode eq "by_song")
      {
        MusicRoom::File::normalise($scratch_dir,$normalise_mode,@temp_files);
      }
    elsif($normalise_mode eq "dynamic")
      {
        MusicRoom::File::normalise($scratch_dir,$normalise_guess,@temp_files);
      }
    foreach my $track (@{$dir})
      {
        my $id = $track->{id};
        my $full_work = "$scratch_dir/$track->{final_filename}\.$working_ext";
        my $full_dest = "$active_target_dir/$final_target_dir/$track->{final_filename}\.$active_ext";
        if(!MusicRoom::File::convert_audio($full_work,$working_format,
                                           $full_dest,$active_format))
          {
            croak("Conversion failed for $working_format to $active_format");
          }
        if(!-r $full_dest)
          {
            croak("Failed to convert file to \"$full_dest\"");
          }
        if(!MusicRoom::File::set_tags($track,$full_dest,$active_format))
          {
            croak("Failed to set tags in \"$full_dest\"");
          }

        # Failing to attach coverart is not a grounds for abandoning 
        # the whole process
        MusicRoom::CoverArt::attach($track,$full_dest,$active_format);

        $track->{size} = int((-s $full_dest)/2);
        foreach my $attr (@required_columns,"size")
          {
            print $ofh "," if($attr ne $required_columns[0]);
            my $val = $track->{$attr};
            if(!defined $val)
              {
                carp("The attribute $attr is not set");
                $val = "";
              }
            if($val =~ /\"/)
              {
                carp("Cannot have <\"> in attribute \"$val\" in $id");
                $val =~ s/\"/\'/g;
              }
            print $ofh "\"$val\"";
          }
        print $ofh "\n";
        progress("\nConverting Files",$num_files_copied++,$num_files_to_copy);
        print "\n";
      }
    $ofh->close();
    empty_scratch(@temp_files);
  }

# Now report on the new id2carry values
add_to_database();

exit 0;

sub read_csvs
  {
    my @files =
      (
        "src-tracks" => \&do_src_tracks,
        "src-id2carry" => \&do_src_id2carry,
        "src-id2best" => \&do_src_id2best,
      );
    for(my $i=0;$i<=$#files;$i+=2)
      {
        my $src_file = MusicRoom::File::latest($files[$i],
                                     dir => $flaccer_dir,look_for => "csv",quiet => 1);
        if(!defined $src_file)
          {
            croak("Cannot find \"$files[$i]\" in $flaccer_dir");
          }
        my $ifh = IO::File->new($src_file);
        if(!defined $ifh)
          {
            croak("Cannot open file \"$src_file\" in $flaccer_dir");
          }
        MusicRoom::Text::CSV::scan($ifh,action => $files[$i+1]);
        $ifh->close();
      }
    my %need_resample = needs_resample();
    my @to_be_resampled;
    my $last_dir = "";
    foreach my $id (sort {$need_resample{$a}->{bestsrc} cmp $need_resample{$b}->{bestsrc} ||
                          $need_resample{$a}->{bestbasedir} cmp $need_resample{$b}->{bestbasedir} ||
                          $need_resample{$a}->{track} <=> $need_resample{$b}->{track} ||
                          $need_resample{$a}->{bestbasefile} cmp $need_resample{$b}->{bestbasefile} ||
                          $need_resample{$a}->{id} cmp $need_resample{$b}->{id}
                          } keys %need_resample)
      {
        # Group the outputs by {bestsrc} and {bestbasedir}
        if($need_resample{$id}->{bestbasedir} ne $last_dir)
          {
            push @to_be_resampled,[];
            $last_dir = $need_resample{$id}->{bestbasedir};
          }
        push @{$to_be_resampled[$#to_be_resampled]},$need_resample{$id};
      }
    return @to_be_resampled;
  }

{
my %all_tracks;

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

sub needs_resample
  {
    # Return all the track records that need to be republished
    my %return;

    foreach my $id (keys %all_tracks)
      {
        next if($all_tracks{$id}->{_have_carry});
        $return{$id} = $all_tracks{$id};
      }
    return %return;
  }
}

sub identify_dir
  {
    my($dir_id,$dir_name) = @_;

    while(1)
      {
        # Attempt to find a given directory on a list of possible drives
        foreach my $drive (@possible_disks)
          {
            return "$drive/"
                           if(-d "$drive/$dir_name");
            return "$drive"
                           if(-d "$drive$dir_name");

            # Sometimes the drive name contains a whole load of dirs 
            # (one for each DVD)
            return "$drive/$dir_id/"
                           if(-d "$drive/$dir_id/$dir_name");
          }

        # Could be a DVD that needs to be inserted, maybe we should ask?
        print "\nCannot find \"$dir_id\" does it need inserting?\n";
        print "Look again?[Y]: ";
        my $response = <>;
        return undef if($response ne "" && $response !~ /^y/i);
      }
  }

sub cur_time
  {
    my($sec,$min,$hour,) = localtime(time);
    return sprintf("%02d:%02d",$hour,$min);
  }

sub check_scratch_empty
  {
    # Check that the scratch direcory is empty
    local(*DIR);
    opendir(DIR,$scratch_dir);
    my @file = readdir(DIR);
    closedir(DIR);

    foreach my $file (@file)
      {
        next if($file =~ /^\.\.?$/);

        croak("The scratch directory $scratch_dir is not empty");
      }
  }

sub empty_scratch
  {
    my(@temp_files) = @_;

    foreach my $file (@temp_files)
      {
        unlink("$scratch_dir/$file");
      }
  }

sub count_files
  {
    my(@dirs) = @_;
    my $total = 0;
    foreach my $dir (@_)
      {
        $total += $#{$dir}+1;
      }
    return $total;
  }

sub make_dir
  {
    # Need to do a recursive build of the dirs, so that 
    # specs like "<dir_artist>/<dir_album>" will get correctly 
    # constructed
    my($dir) = @_;

    if($dir =~ m#/+([^/]+)$#)
      {
        my $parent = $`;
        make_dir($parent) if(!-d $parent);
      }
    mkdir $dir,0755;
  }

sub progress
  {
    my($text,$cur_file,$num_files) = @_;

    $| = 1;
    $cur_file = $num_files if($cur_file > $num_files);
    my $out = show_bar($cur_file/$num_files,30,"bar","#",".");
    print "\r$text $out";
  }

sub show_bar
  {
    # Create an ASCII progressbar
    my($proportion,$width,$type,$ind,$bg) = @_;

    my $bar = $bg x $width;
    my $loc = int($proportion*$width);

    if($type eq "point")
      {
        substr($bar,$loc,1) = $ind;
      }
    elsif($type eq "bar")
      {
        substr($bar,0,$loc) = $ind x $loc;
      }
    else
      {
        error("Cannot yet do $type bars");
      }
    return $bar;
  }

sub dosify
  {
    my($name) = @_;

    # Take a perfectly good name and mess it up
    $name =~ s#/#\\#g;
    return $name;
  }

sub add_to_database
  {
    # There have to be two varients of this, while the old system (using 
    # csv files) is in place I need some files formated specially for
    # them.  I will later need to insert new tracks into the database

    # For the moment we know that only the id2carry type files need to 
    # be regenerated by this process
    my %csv_files =
      (
#        src_track => ['id','track','length','artist','title','album',
#                      'dir_artist','dir_album','dir_name','size',
#                      'quality','year'],
#        src_id2best => ['id','bestsrc','original_format','bestbasename'],
        src_id2carry => ['id','carrysrc','carryformat','carrybasename'],
        track => \@required_columns,
      );

    my $room_dir = MusicRoom::get_conf("dir");
    my %global_vals =
      (
        bestsrc => 'bestXXX',
        carrysrc => 'carryXX',
        carryformat => $active_format,
      );

    foreach my $csv_file (keys %csv_files)
      {
        my $dest_file = MusicRoom::File::new_name(
                             "$room_dir/resample-$csv_file","csv");
        my $ofh = IO::File->new(">".$dest_file);
        if(!defined $ofh)
          {
            carp("Cannot open file $dest_file");
            next;
          }
        print $ofh join(',',@{$csv_files{$csv_file}})."\n";
        foreach my $dir (@resample_dirs)
          {
            foreach my $track (@{$dir})
              {
                my $id = $track->{id};

                foreach my $attrib (@{$csv_files{$csv_file}})
                  {
                    print $ofh "," if($attrib ne $csv_files{$csv_file}->[0]);
                    my $val;
                    if($attrib eq 'length')
                      {
                        my $hour = int($track->{length_secs} / (60*60));
                        my $mins = int($track->{length_secs} / 60) % 60;
                        my $secs = $track->{length_secs} % 60;
                        if($hour > 0)
                          {
                            $val = sprintf("%d:%02d:%02d",$hour,$mins,$secs);
                          }
                        else
                          {
                            $val = sprintf("%02d:%02d",$mins,$secs);
                          }
                      }
                    elsif($attrib eq 'track')
                      {
                        $val = sprintf("%02d",$track->{track_num});
                      }
                    elsif($attrib eq 'bestbasename')
                      {
                        $val = "./".$track->{target_dir}."/".
                                    $track->{target_file};
                      }
                    elsif($attrib eq 'carrybasename')
                      {
                        $val = "./".$track->{target_dir}."/".
                                    $track->{target_file};
                      }
                    elsif($attrib eq 'dir_name')
                      {
                        $val = $track->{target_dir};
                      }
                    elsif(defined $track->{$attrib})
                      {
                        $val = $track->{$attrib};
                      }
                    elsif(defined $global_vals{$attrib})
                      {
                        $val = $global_vals{$attrib};
                      }
                    else
                      {
                        carp("Cannot find value for $attrib (in $id)");
                        $val = "";
                      }
                    print $ofh "\"$val\"";
                  }
                print $ofh "\n";
            }
          }
        $ofh->close();
      }
    
#    foreach my $id (keys %tag_data)
#      {
#        # Insert this item into the database
#      }
  }
    
    
