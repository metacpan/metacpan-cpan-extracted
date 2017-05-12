#!/bin/env perl

# Script that lists music files from a given location

use strict;
use warnings;

use MusicRoom;
use Carp;

my $dir = ".";
$dir = shift(@ARGV) if($#ARGV == 0);

my $nam = lc($dir);
$nam =~ s#[/\\\-\.\s]+#_#g;
$nam =~ s#[^a-z0-9_]+##ig;
$nam =~ s#^_+##;
$nam =~ s#_+$##;

my $file_name = MusicRoom::File::new_name("$nam-music-tags","csv");
my @music_files = @ARGV;

# Need all dir seperators to be / rather than \
$dir =~ s#\\#/#g;

@music_files = list_music_files($dir)
                     if(!@music_files);

open(OUT,">".$file_name);

my @details = (MusicRoom::Track::attribs(),"root_path","dir","file");

foreach my $attrib (@details)
  {
    print OUT "," if($attrib ne $details[0]);
    print OUT $attrib;
  }
print OUT "\n";

my %tracks;

foreach my $file (@music_files)
  {
    my %attribs = MusicRoom::File::get_tags($file);

    foreach my $attrib (@details)
      {
        my $val;
        if($attrib eq "root_path")
          {
            $val = $dir;
          }
        elsif($attrib eq "dir")
          {
            $val = $file;
            $val =~ s#^$dir/+##i;
            if($val =~ m#/+([^/]*)$#)
              {
                $val = $`;
              }
            else
              {
                $val = "";
              }
          }
        elsif($attrib eq "file")
          {
            $val = $file;
            $val =~ s#^$dir/+##i;
            if($val =~ m#/+([^/]*)$#)
              {
                $val = $1;
              }
            else
              {
                # File at top level
              }
          }
        else
          {
            $val = $attribs{$attrib};
          }
        $val = "" if(!defined $val);

        # We must ensure that there are no doublequotes
        if($val =~ /\"/)
          {
            carp("Cannot allow <\"> in attribute $attrib (Value |$val|)");
            $val =~ s#\"#\'#g;
            if($attrib eq "root_path" || $attrib eq "dir" ||
                              $attrib eq "file")
              {
                # This effectively prevents us from dealing with 
                # this file (but who uses " in file names?)
                carp("$attrib has been changed to |$val| ".
                     "probably need to chnge the file");
              }
          }
        print OUT "," if($attrib ne $details[0]);
        print OUT "\"$val\"";
      }
    print OUT "\n";
  }
close(OUT);
exit 0;

sub album_artist
  {
    my($file) = @_;
    if($file =~ m#/([^/]+)\s*\-([^/\-]+)/+[^/]+#)
      {
        my $artist = $1;
        return "various"
                    if($artist =~ /various/i);
        return $artist;
      }
    else
      {
        print STDERR "Cannot pick out album artist from \"$file\"\n";
        return "unknown";
      }
  }

sub list_music_files
  {
    my($dir) = @_;
    
    if(!-d $dir)
      {
        carp("Cannot find directory \"$dir\"");
        return ();
      }

    local(*DIR);
    opendir(DIR,$dir);
    my @files = readdir(DIR);
    closedir(DIR);

    # Sort the files by last modification date (to make defining track 
    # numbers easier when there are no other clues)
    my $by_modification_date = sub
      {
        return (-M "$dir/$b") <=> (-M "$dir/$a");
      };
    my @ret;
    foreach my $file (sort $by_modification_date @files)
      {
        next if($file =~ /^\.\.?$/);
        my $full_name = "$dir/$file";
        if(-d $full_name)
          {
            push @ret,list_music_files($full_name);
            next;
          }
        # Is this a music file?
        if($full_name =~ /\.([^\.]+)$/)
          {
            # Only way to tell at the moment is by the extension
            # should use a "file" command really
            my $ext = lc($1);
            if(MusicRoom::File::is_music_extension($ext))
              {
                push @ret,$full_name;
              }
            next;
          }
      }
    return @ret;
  }

