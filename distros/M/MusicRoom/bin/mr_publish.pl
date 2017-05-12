#!/bin/env perl

# Publish a set of music to the repository.  This consists of:
#
#     Doing some quick tests to ensure the supplied tags are valid
#     Generating the final IDs for all the music
#     Moving the data into the "orginal" zone (without manipulating)
#     Generating a record of what data is contained in every dir
#     Processing the data to generate audio in the right format
#     Inserting the new records into the database
#
# Only once all the steps have been carried out can the music be said to 
# have been published.
# While doing this it is important that no other "publish" process is proceeding
# otherwise we will get clashes of IDs, directory names and file names
#

use strict;
use warnings;

use Carp;
use MusicRoom;
use IO::File;
use File::Copy;

# Various bits of configuration that should come from
# the config file (eventually)

# This spec must only use / as a seperator and cannot either 
# start or end in a /
my $best_dir_spec = "<dir_artist> - <dir_album>";
my $best_file_spec = "<artist> - <title>";
my $active_format = "mp3:128";

# Modes are "none", "by_file", "by_dir", "dynamic"
my $normalise_mode = "dynamic";

my $best_target_dir = "D:\\mydata\\music\\disc\\best069";
# my $active_target_dir = "D:\\mydata\\music\\cd_split\\carry22";
my $active_target_dir = "F:\\music\\";
$active_target_dir = "G:\\music\\"
                        if(!-d $active_target_dir);
$active_target_dir = "H:\\music\\"
                        if(!-d $active_target_dir);
$active_target_dir = "E:\\music\\"
                        if(!-d $active_target_dir);
my $scratch_dir = "build_tmp";

my $process_failed = "";

$| = 1;

######################################################################
# Check the setup and find the source file
######################################################################

croak("Must nominate a set to process as an argument to the script")
                                                              if($#ARGV < 0);
my $nam = shift(@ARGV);

croak("Cannot find best data target directory $best_target_dir")
                                    if(!-d $best_target_dir);
croak("Cannot find active target directory $active_target_dir")
                                    if(!-d $active_target_dir);
if(!-d $scratch_dir)
  {
    make_dir($scratch_dir);
    croak("Cannot create directory $scratch_dir")
                                  if(!-d $scratch_dir);
  }
check_scratch_empty();

my(%tag_data,%dirs,%new_dirs,%new_files,@id_order);

my $final_file_basename = "$nam-final";
my $perdir_listing = "tracks";

my $src_file = MusicRoom::File::latest($final_file_basename,
                                       look_for => "csv",quiet => 1);
if(!defined $src_file)
  {
    croak("Cannot find \"$src_file\" file (need to rename to final?)");
  }
my $ifh = IO::File->new($src_file);
if(!defined $ifh)
  {
    croak("Cannot open file \"$src_file\"");
  }

######################################################################
# Read the tags into the data structures, checking that they look valid
######################################################################

my @required_columns = 
  (
    "id","artist","title","album","dir_artist","dir_album",
    "track_num","length_secs","quality","original_format",
    "year","target_dir","target_file","original_ext",
  );

my $ids_are_6chars = "";
MusicRoom::Text::CSV::scan($ifh,action => \&add_entry);
$ifh->close();

croak("Tags appear to not be valid")
                        if($process_failed);
  
######################################################################
# Move the files to the "best" directories
######################################################################
files_to_original();

croak("Copy to original repository failed")
                        if($process_failed);

######################################################################
# Convert the data to the right format for the active set
######################################################################

convert_for_active();

croak("Converting and normalising failed")
                        if($process_failed);

######################################################################
# Inserting the new records into the database
######################################################################
add_to_database();

exit 0;

sub add_entry
  {
    my(%attribs) = @_;

    # The id we have in the CSV file is probably a temporary one just 
    # for the purpose of fixing the tags, if it is *not* 6 characters 
    # long we assign a new one
    my $id = $attribs{id};
    if(length($id) == 6 && !$ids_are_6chars)
      {
        carp("IDs are 6 characters long, will assume they are valid for this repository");
        $ids_are_6chars = 1;
      }

    while(length($id) != 6)
      {
        $id = MusicRoom::STN::unique(\%tag_data,6);
        # Does this match an existing track in the repository?
        my $track = MusicRoom::Track::id2obj($id);
        if(defined $track)
          {
            # That ID is already used, try again
            $id = "";
          }
      }
    $attribs{id} = $id;

    # Work out where this directory should go
    my $orig_target_dir = MusicRoom::Locate::expand(\%attribs,$best_dir_spec);

    if(!defined $dirs{$orig_target_dir})
      {
        # This is the first time we have encountered this dir, does it already 
        # exist?
        my $count = 1;
        my $final_target_dir = $orig_target_dir;

        # We want to ensure that the directory is unique for the best 
        # and active directories
        while(-d "$best_target_dir/$final_target_dir" || 
                  -d "$active_target_dir/$final_target_dir" || 
                  defined $new_dirs{$final_target_dir})
          {
            $count++;
            $final_target_dir = "$orig_target_dir($count)";
          }
        $new_dirs{$final_target_dir} = 1;
        $dirs{$orig_target_dir} = {real_dir => $final_target_dir,id_list => [],
                              location => "$best_target_dir/$final_target_dir"};
      }

    $attribs{target_dir} = $dirs{$orig_target_dir}->{real_dir};
    push @{$dirs{$orig_target_dir}->{id_list}},$id;

    # Copy the extension from the original file
    my $extension = "_";
    $extension = $1
             if($attribs{file} =~ /(\.[^\.]*)$/);
    $attribs{original_ext} = $extension;

    my $orig_target_file = MusicRoom::Locate::expand(\%attribs,$best_file_spec);
    my $final_target_file = "$orig_target_file";
    my $count = 1;

    # As long as we have existing tracks with the same name keep moving
    while(defined $new_files{"$attribs{target_dir}/$final_target_file"})
      {
        $count++;
        $final_target_file = "$orig_target_file($count)";
      }

    $attribs{target_file} = $final_target_file;
    $new_files{"$attribs{target_dir}/$final_target_file"} = 1;

    foreach my $attrib (@required_columns)
      {
        if(!defined $attribs{$attrib} || $attribs{$attrib} eq "")
          {
            carp("Cannot find $attrib for $attribs{id}");
            $process_failed = 1;
          }
      }

    push @id_order,$id;

    $tag_data{$id} = \%attribs;
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

sub files_to_original
  {
    my $num_files_to_copy = scalar keys %tag_data;
    my $num_files_copied = 0;

    print "\nCopying started ".cur_time()."\n";

    foreach my $orig_dir (sort keys %dirs)
      {
        my $dir = $dirs{$orig_dir}->{real_dir};

        progress("Copying Files",$num_files_copied,$num_files_to_copy);

        make_dir("$best_target_dir/$dir");
        if(!-d "$best_target_dir/$dir")
          {
            carp("Cannot make directory \"$best_target_dir/$dir\"");
            $process_failed = 1;
            next;
          }
        
        my $dest_file = MusicRoom::File::new_name(
                             "$best_target_dir/$dir/$perdir_listing","csv");
        my $ofh = IO::File->new(">".$dest_file);
    
        if(!defined $ofh)
          {
            carp("Cannot open file $dest_file");
            $process_failed = 1;
            next;
          }
    
        print $ofh join(',',@required_columns)."\n";

        # Now process each file in turn
        foreach my $id (@{$dirs{$orig_dir}->{id_list}})
          {
            my $td = $tag_data{$id};

            my $full_src = "$td->{root_path}/$td->{dir}/$td->{file}";

            if(!-r $full_src)
              {
                carp("Cannot read file \"$full_src\" (misnamed dir?)");
                $process_failed = 1;
                next;
              }
            my $full_dest = "$best_target_dir/$dir/$td->{target_file}$td->{original_ext}";
            copy($full_src,$full_dest);
            if(!-r $full_dest)
              {
                carp("Failed to copy file to \"$full_dest\"");
                $process_failed = 1;
                next;
              }
            elsif(-s $full_src != -s $full_dest)
              {
                carp("Target file different sizes from source \"$full_dest\"");
                $process_failed = 1;
                next;
              }
            foreach my $attr (@required_columns)
              {
                print $ofh "," if($attr ne $required_columns[0]);
                my $val = $td->{$attr};
                if($val =~ /\"/)
                  {
                    carp("Cannot have <\"> in attribute \"$val\" in $id");
                    $val =~ s/\"/\'/g;
                  }
                print $ofh "\"$val\"";
              }
            print $ofh "\n";
            progress("Copying Files",$num_files_copied++,$num_files_to_copy);
          }
        $ofh->close();
      }
    print "\nCopying complete ".cur_time()."\n";
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

sub progress
  {
    my($text,$cur_file,$num_files) = @_;

    $| = 1;
    $cur_file = $num_files if($cur_file > $num_files);
    my $out = show_bar($cur_file/$num_files,30,"bar","#",".");
    print "\r$text $out";
  }

sub convert_for_active
  {
    # We have two tasks per file, getting if from the best and 
    # putting it into the active
    my $num_files_to_copy = 2*(scalar keys %tag_data);
    my $num_files_copied = 0;

    # Work out the standard format we are going to use in the active area
    my $working_format = MusicRoom::File::working_format();
    my $working_ext = MusicRoom::File::formats_extension($working_format);
    my $active_ext = MusicRoom::File::formats_extension($active_format);

    foreach my $orig_dir (keys %dirs)
      {
        check_scratch_empty();
        my @temp_files = ();

        my $dir = $dirs{$orig_dir}->{real_dir};

        my $dir_start_time = cur_time();
        print "Started $dir_start_time \"$dir\"\n";
        progress("Converting Files",$num_files_copied,$num_files_to_copy);

        make_dir("$active_target_dir/$dir");
        if(!-d "$active_target_dir/$dir")
          {
            carp("Cannot make directory \"$active_target_dir/$dir\"");
            $process_failed = 1;
            next;
          }
        my $dest_file = MusicRoom::File::new_name(
                             "$active_target_dir/$dir/$perdir_listing","csv");
        my $ofh = IO::File->new(">".$dest_file);
        if(!defined $ofh)
          {
            carp("Cannot open file $dest_file");
            $process_failed = 1;
            next;
          }
        print $ofh join(',',@required_columns,"size")."\n";

        my $normalise_guess = "by_dir";
        # Transcribe all the files into the scratch directory
        foreach my $id (@{$dirs{$orig_dir}->{id_list}})
          {
            my $td = $tag_data{$id};

            # This time we get the data from the best directory
            my $full_src = "$best_target_dir/$dir/$td->{target_file}$td->{original_ext}";
            my $full_dest = "$scratch_dir/$td->{target_file}.$working_ext";

            progress("\nConverting Files",$num_files_copied++,$num_files_to_copy);
            print "\n";
            if(!MusicRoom::File::convert_audio($full_src,$td->{original_format},
                                           $full_dest,$working_format))
              {
                $process_failed = 1;
                next;
              }

            if(!-r $full_dest)
              {
                carp("Failed to convert to $full_dest");
                $process_failed = 1;
                next;
              }
            push @temp_files,"$td->{target_file}.$working_ext";

            $normalise_guess = "by_song" if($td->{dir_artist} eq "Various Artists");
          }

        # Now do we want to normalise?
        if($normalise_mode eq "by_dir" || $normalise_mode eq "by_song")
          {
            MusicRoom::File::normalise($scratch_dir,$normalise_mode,@temp_files);
          }
        elsif($normalise_mode eq "dynamic")
          {
            MusicRoom::File::normalise($scratch_dir,$normalise_guess,@temp_files);
          }
        
        # Now process each file in turn
        foreach my $id (@{$dirs{$orig_dir}->{id_list}})
          {
            my $td = $tag_data{$id};

            my $full_src = "$scratch_dir/$td->{target_file}.$working_ext";
            my $full_dest = "$active_target_dir/$dir/$td->{target_file}.$active_ext";

            if(!MusicRoom::File::convert_audio($full_src,$working_format,
                                           $full_dest,$active_format))
              {
                $process_failed = 1;
                next;
              }
            if(!-r $full_dest)
              {
                carp("Failed to copy file to \"$full_dest\"");
                $process_failed = 1;
                next;
              }
            if(!MusicRoom::File::set_tags($tag_data{$id},$full_dest,$active_format))
              {
                $process_failed = 1;
                next;
              }

            # Failing to attach coverart is not a grounds for abandoning 
            # the whole process
            MusicRoom::CoverArt::attach($tag_data{$id},$full_dest,$active_format);

            $td->{size} = int((-s $full_dest)/2);
            foreach my $attr (@required_columns,"size")
              {
                print $ofh "," if($attr ne $required_columns[0]);
                my $val = $td->{$attr};
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
  }

sub add_to_database
  {
    # There have to be two varients of this, while the old system (using 
    # csv files) is in place I need some files formated specially for
    # them.  I will later need to insert new tracks into the database

    my %csv_files =
      (
        src_track => ['id','track','length','artist','title','album',
                      'dir_artist','dir_album','dir_name','size',
                      'quality','year'],
        src_id2best => ['id','bestsrc','original_format','bestbasename'],
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
                             "$room_dir/$nam-$csv_file","csv");
        my $ofh = IO::File->new(">".$dest_file);
        if(!defined $ofh)
          {
            carp("Cannot open file $dest_file");
            next;
          }
        print $ofh join(',',@{$csv_files{$csv_file}})."\n";
        foreach my $id (@id_order)
          {
            foreach my $attrib (@{$csv_files{$csv_file}})
              {
                print $ofh "," if($attrib ne $csv_files{$csv_file}->[0]);
                my $val;
                if($attrib eq 'length')
                  {
                    my $hour = int($tag_data{$id}->{length_secs} / (60*60));
                    my $mins = int($tag_data{$id}->{length_secs} / 60) % 60;
                    my $secs = $tag_data{$id}->{length_secs} % 60;
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
                    $val = sprintf("%02d",$tag_data{$id}->{track_num});
                  }
                elsif($attrib eq 'bestbasename')
                  {
                    $val = "./".$tag_data{$id}->{target_dir}."/".
                                $tag_data{$id}->{target_file};
                  }
                elsif($attrib eq 'carrybasename')
                  {
                    $val = "./".$tag_data{$id}->{target_dir}."/".
                                $tag_data{$id}->{target_file};
                  }
                elsif($attrib eq 'dir_name')
                  {
                    $val = $tag_data{$id}->{target_dir};
                  }
                elsif(defined $tag_data{$id}->{$attrib})
                  {
                    $val = $tag_data{$id}->{$attrib};
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
        $ofh->close();
      }

    foreach my $id (keys %tag_data)
      {
        # Insert this item into the database
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

