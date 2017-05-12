package MusicRoom::Locate;

use strict;
use warnings;
use Carp;

use constant PATHS_SPEC => "musicroom_paths";

my %categories;

sub scan_dir
  {
    my($category) = @_;

    return if(defined $categories{$category});

    my $mr_dir = MusicRoom::get_conf("dir");
    croak("Cannot locate MusicRoom directory")
                                     if(!defined $mr_dir);
    my $mr_art_subdir = MusicRoom::get_conf("${category}_subdir");
    croak("Cannot locate config parameter ${category}_subdir")
                                     if(!defined $mr_art_subdir);
    my $src_dir = $mr_dir.$mr_art_subdir;

    croak("\u${category} direcory \"$src_dir\" cannot be found")
                        if(!-d $src_dir);
    croak("Cannot read cover art from directory $src_dir")
                        if(!-r $src_dir);

    # To read the coverart we have to scan the spec file
    croak("Cannot read paths list")
                        if(!-r "$src_dir/".PATHS_SPEC);

    my $ifh = IO::File->new("$src_dir/".PATHS_SPEC);
    croak("Failed to open $src_dir/".PATHS_SPEC)
                        if(!defined $ifh);

    my @locate_specs;

    while(my $line = <$ifh>)
      {
        chomp($line);
        $line =~ s/\cZ+//;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next if($line =~ /^#/);
        next if($line eq "");
        push @locate_specs,$line;
      }
    $ifh->close();
    $categories{$category} = 
      {
        paths => \@locate_specs,
        dir => $src_dir
      };
  }

sub dir_of
  {
    my($category) = @_;

    croak("Must call scan_dir() for each category before using it")
                                      if(!defined $categories{$category});
    return $categories{$category}->{dir};
  }

sub paths
  {
    my($category) = @_;

    croak("Must call scan_dir() for each category before using it")
                                      if(!defined $categories{$category});
    return $categories{$category}->{paths};
  }

sub locate
  {
    my($track,$category) = @_;

    croak("Must call scan_dir() for each category before using it")
                                      if(!defined $categories{$category});

    foreach my $image_file (@{$categories{$category}->{paths}})
      {
        my $candidate_path = $categories{$category}->{dir}."/".
                                expand($track,$image_file);
        return $candidate_path 
                         if(-r $candidate_path);
      }
    return undef;
  }

sub search_for
  {
    # Return a list of the files that the locate would search for
    my($track,$category) = @_;

    croak("Must call scan_dir() for each category before using it")
                                      if(!defined $categories{$category});
    my @search_paths;
    foreach my $image_file (@{$categories{$category}->{paths}})
      {
        my $candidate_path = expand($track,$image_file);
        push @search_paths,$candidate_path;
      }
    return @search_paths;
  }

sub expand
  {
    my($track,$spec) = @_;
    if(!ref($track))
      {
        croak("Must provide a track record");
      }

    while($spec =~ /<([^<>]+)>/)
      {
        my $attrib = $1;
        my $val;
        if(ref($track) eq "HASH")
          {
            $val = $track->{$attrib};
          }
        elsif(ref($track) eq MusicRoom::Track::perl_class())
          {
            $val = $track->get($attrib);
            if(ref($val))
              {
                $val = $val->name();
              }
          }
        else
          {
            carp("Cannot yet expand from ".ref($track))
          }
        if(!defined $val)
          {
            carp("Cannot find value for attribute \"$attrib\"");
            $val = "";
          }
        # Make the name compatible with file systems
        $val = MusicRoom::File::tidy($val);
        $spec =~ s/<$attrib>/$val/g;
      }
    return $spec;
  }

1;
