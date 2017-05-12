#!/bin/env perl

# This script performs various exercises to fix a set of tags.  The script is the 
# second stage for importing music to the validated set.  The general picture is:
#
#    Step 1: Read tags from a nominated music source
#    Step 2: Fix the tags so they pass all the validation tests
#    Step 3: Use the fixed tag data to bring the music in
#
# This second stage is the critical one since the tags must meet all the validation 
# criteria *before* the tracks can be loaded.  So the question is what tests do 
# the users want to perform and what actions do they want to take on music that fails
# to meet the standard?

use strict;
use warnings;

use Carp;
use MusicRoom;
use MusicRoom::STN;
use Carp;
use IO::File;
use Term::ReadKey;

if($#ARGV < 0)
  {
    croak("Must nominate a set to process as an arg to the script");
  }
my $nam = shift(@ARGV);

my $edit_tags = "edit-tags";
my $edit_file_basename = "$nam-${edit_tags}";
my $first_file_basename = "$nam-music-tags";
my $final_file_basename = "$nam-final";
my(%tag_data,%fixes,%checks,%failed_ids);

define_checks();

my @columns =
  (
    "id","artist","title","album","dir_artist","dir_album",
    "track_num","length_secs","quality","original_format",
    "year","root_path","dir","file"
  );

# Now read the description of the processing to be done
read_actions();

# Read the existing set of tags in, either from an edited set or from the 
# list_music script
my $src_file = MusicRoom::File::latest($edit_file_basename,
                                       look_for => "csv",quiet => 1);
if(!defined $src_file)
  {
    # Maybe this is the first attempt to process this music
    $src_file = MusicRoom::File::latest($first_file_basename,look_for => "csv");

    if(!defined $src_file)
      {
        croak("Cannot find either \"$edit_file_basename\" or \"$first_file_basename\" file");
        exit 20;
      }
  }
my $ifh = IO::File->new($src_file);
if(!defined $ifh)
  {
    croak("Cannot open file \"$src_file\"");
  }

MusicRoom::Text::CSV::scan($ifh,action => \&add_entry);
$ifh->close();

$|=1;

print "\n" . "-"x70 ."\n";
print <<"EndHeader";
TsorT tag fixer: Part of the MusicRoom system.

The program will take some time to load the lists of valid values, 
especially when new valid values have just been added.  
Thank you for your understanding.
EndHeader

my $complained = 0;

while(1)
  {
    # First we list the fixed actions that are always present
    my %top_actions =
      (
        w => 
          {
            description => 'Save current state',
            action => \&save_tags,
          },
        x =>
          {
            description => 'Save and exit',
            action => sub {save_tags();exit 0;},
          },
        q =>
          {
            description => 'Exit without saving',
            action => sub {exit 0;},
          },
      );

    # We have three levels of interaction:
    #
    #    We can select which issue to focus on fixing
    #    We can select an action that fixes an issue
    #    We can perform an action
    #
    # This is the highest level, find out which issues need to 
    # be addressed.
    my @issues = current_issues();

    my $selected_issue;
    if($#issues < 0)
      {
        # I don't think this should ever happen
        select_action("There are no outstanding issues",%top_actions);
        next;
      }
    elsif($#issues == 0)
      {
        $selected_issue = $issues[0];
      }
    else
      {
        # We have multiple issues, select one to go with
        my %picklist;
        for(my $i=0;$i<=$#issues;$i++)
          {
            my $key = $i+1;
            $key = pack('c',ord('a')+$key-10) if($key > 9);

            $picklist{$key} =
              {
                description => $checks{$issues[$i]}->{description},
                issue => $issues[$i],
              };
          }

        my $action = select_action("The following issues need to be resolved",
                         %top_actions,%picklist);
        $selected_issue = $picklist{$action}->{issue}
                              if(defined $picklist{$action});
      }

    next if(!defined $selected_issue || !defined $checks{$selected_issue});

    if(!defined $checks{$selected_issue}->{fixes} ||
           ref($checks{$selected_issue}->{fixes}) ne "ARRAY" ||
               $#{$checks{$selected_issue}->{fixes}} < 0)
      {
        carp("Cannot find any fixes to get $selected_issue");
        next;
      }
    if(($#{$checks{$selected_issue}->{fixes}} % 2) == 0)
      {
        carp("Odd number of items in $selected_issue fixes (bad configuration)");
        next;
      }

    # By this point we know which issue the user has selected, there are 
    # a number of ways that this issue could be fixed, get the user 
    # to pick one
    my($selected_fix,$fix_args);
    if($#{$checks{$selected_issue}->{fixes}} == 1)
      {
        # There is only one fix, we have no choice
        $selected_fix = $checks{$selected_issue}->{fixes}->[0];
        $fix_args = $checks{$selected_issue}->{fixes}->[1];
      }
    else
      {
        # Pick which of the fixes we want to apply next
        my %picklist;
        my @fixes = @{$checks{$selected_issue}->{fixes}};
        for(my $i=0;$i<=$#fixes;$i+=2)
          {
            my $key = int($i/2)+1;
            $key = pack('c',ord('a')+$key-10) if($key > 9);

            my $suggested_fix = $fixes[$i];
            my $suggested_args = $fixes[$i+1];

            if(!defined $fixes{$suggested_fix})
              {
                carp("Cannot find fix instruction for |$suggested_fix|");
                next;
              }

            $picklist{$key} =
              {
                description => $fixes{$suggested_fix}->{description},
                action => [$suggested_fix,$suggested_args],
              };
          }

        my $information;
        my $example;
        $example = &{$checks{$selected_issue}->{show_example}}()
                      if(defined $checks{$selected_issue}->{show_example});

        if(!defined $example || $example eq "")
          {
            $information = <<"EndInfo";
$checks{$selected_issue}->{description}

There is a choice of ways to resolve this
EndInfo
          }
        else
          {
            $information = <<"EndInfo";
$checks{$selected_issue}->{description}

For example:
$example

There is a choice of ways to resolve this
EndInfo
          }
        my $fix_to_apply = select_action($information,
                             %top_actions,%picklist);

        next
              if(!defined $fix_to_apply || ref($fix_to_apply) ne "ARRAY");

        ($selected_fix,$fix_args) = @{$fix_to_apply};
      }

    # So now we know the issue to address and how we want to address 
    # it we can actually get on with some work
    if(!defined $fixes{$selected_fix})
      {
        carp("Cannot find a fix called $selected_fix");
        next;
      }
    if(!defined $fixes{$selected_fix}->{action})
      {
        carp("Fix $selected_fix does not have an action defined");
        next;
      }

    # Call the fix that has been selected
    &{$fixes{$selected_fix}->{action}}($failed_ids{$selected_issue},
                                       @{$fix_args});
    # Save the current state and go round again
    save_tags();
  }

exit 0;

sub select_action
  {
    # Put a list of choices up on the terminal and have the user select 
    # an action to take
    my($notice,%actions) = @_;

    print "\n" . "-"x70 ."\n";
    print $notice."\n\n";
    print "Next action:\n";
    foreach my $key (sort keys %actions)
      {
        print "    $key - $actions{$key}->{description}\n";
      }
    print "\nSelect Action: ";

    my $input = read_single_key();
    print "$input\n";

    if(defined $actions{$input})
      {
        return $input if(!defined $actions{$input}->{action});

        return &{$actions{$input}->{action}}()
                  if(ref($actions{$input}->{action}) eq "CODE");
        return $actions{$input}->{action};
      }
    else
      {
        print "There is no action associated with <$input>\n";
        return undef;
      }
  }

sub read_single_key
  {
    my $input;
    while(!defined $input)
      {
        $input = ReadKey 120;
        print "\nPress a key\n"
                    if(!defined $input && !$complained);
        $complained = 1;
      }
    return $input;
  }

sub add_entry
  {
    my(%attribs) = @_;

    my $id_length = 4;
    if(int(keys %tag_data) > int((32**$id_length)/10))
      {
        carp("Warning: Processing ".int(%tag_data).
                 " songs in one go, it is advisable to split into smaller sets");
      }

    # The unique key has to be specially generated for this run (this is 
    # probably the first pass)
    if(!defined $attribs{id} || $attribs{id} eq "")
      {
        # Making the id 4 charaters long clearly signals that this 
        # is unique only over the duration of this run and that when 
        # adding into the real data a different unique key must be used, 
        # however it also means that we cannot deal with more than 1,048,576 
        # songs being added at any one time (which should be enough for anyone
        # I would think)
        $attribs{id} = MusicRoom::STN::unique(\%tag_data,4);
      }

    # Validate that we have all the columns we expect and nothing more
    delete $attribs{action};

    my %got_col;
    foreach my $col (@columns)
      {
        if(defined $attribs{$col})
          {
            $got_col{$col} = 1;
          }
        else
          {
            carp("Column $col missing from $attribs{id}");
            $attribs{$col} = "";
          }
      }

    foreach my $col (keys %attribs)
      {
        if(!defined $got_col{$col})
          {
            carp("Extra Column $col in $attribs{id}");
          }
      }

    # Add to the building data structure
    $tag_data{$attribs{id}} = \%attribs;
  }

sub save_tags
  {
    # We have reached a checkpoint and want to save our work up to this point
    my $dest_file = MusicRoom::File::new_name($edit_file_basename,"csv");
    if(!defined $dest_file || $dest_file eq "")
      {
        croak("Failed to locate new file $edit_file_basename");
      }
    my $ofh = IO::File->new(">".$dest_file);
    if(!defined $ofh)
      {
        carp("Failed to open file \"$dest_file\" for writing");
        return 0;
      }

    print $ofh join(',',@columns)."\n";
    foreach my $id (sort order_entries keys %tag_data)
      {
        # Ensure we have no doublequotes in the data we are saving
        foreach my $attrib (@columns)
          {
            print $ofh "," if($attrib ne $columns[0]);
            my $val = $tag_data{$id}->{$attrib};
            if(!defined $val)
              {
                carp("Attribute $attrib in $id is undefined");
                $val = "";
              }
            if($val =~ s#\"#\'#g)
              {
                carp("Character <\"> is not allowed in $attrib in $id");
              }
            print $ofh "\"$val\"";
          }
        print $ofh "\n";
      }
    $ofh->close();    
    return 1;
  }

sub order_entries
  {
    # Pick an order that makes sense for music tags, that is sort by
    #     dir_artist, dir_album, track_num   if(dir_artist && dir_album)
    #     dir, track_num   otherwise
    my $order = 0;
    $order = lexically($tag_data{$a}->{dir_artist},
                          $tag_data{$b}->{dir_artist})
           if($tag_data{$a}->{dir_artist} ne "" && 
                          $tag_data{$b}->{dir_artist} ne "");
    return $order if($order != 0);
    $order = lexically($tag_data{$a}->{dir_album},
                          $tag_data{$b}->{dir_album})
           if($tag_data{$a}->{dir_album} ne "" && 
                          $tag_data{$b}->{dir_album} ne "");
    return $order if($order != 0);

    # Use the directory name to sort them
    $order = lexically($tag_data{$a}->{dir},
                          $tag_data{$b}->{dir})
           if($tag_data{$a}->{dir} ne "" && 
                          $tag_data{$b}->{dir} ne "");
    return $order if($order != 0);

    # If the track number is not set treat is as infinite (ie put the 
    # entry on the end of the list)
    if($tag_data{$a}->{track_num} =~ /\d/)
      {
        if($tag_data{$b}->{track_num} =~ /\d/)
          {
            $order = $tag_data{$a}->{track_num} <=> $tag_data{$b}->{track_num};
          }
        else
          {
            return -1;
          }
      }
    elsif($tag_data{$b}->{track_num} =~ /\d/)
      {
        return 1;
      }
    return $order if($order != 0);

    # So by now we suspect that the dir_artist and dir_album are not 
    # set, lets 
    $order = lexically($tag_data{$a}->{dir},
                          $tag_data{$b}->{dir});
    return $order if($order != 0);
    $order = lexically($tag_data{$a}->{file},
                          $tag_data{$b}->{file});

    # If these are different entries with the same dir and file name then 
    # we have some serious problems
    $order;
  }

sub lexically
  {
    # This routine gives us a sort order that more closely matches what 
    # a naive use would expect (ie "9-z" comes before "10-a")
    my($a_,$b_) = @_;

    # If we are called by sort the old @_ gets left around
    # we want to detect this and grab values from $a and $b
    if(!defined($a_) || !defined($b_) ||
         ref($a_) || ref($b_) || $#_ != 1)
      {
        $a_ = $a;
        $b_ = $b;
      }
    return 0
        if($a_ eq "" && $b_ eq "");
    return -1
        if($a_ eq "");
    return 1
        if($b_ eq "");

    my($a_1,$a_t,$a_2,$b_1,$b_t,$b_2);

    if($a_ =~ /^(\d+)/)
      {
        $a_t = 0; $a_1 = $1; $a_2 = $';
      }
    elsif($a_ =~ /^(\D+)/)
      {
        $a_t = 1; $a_1 = $1; $a_2 = $';
      }
    if($b_ =~ /^(\d+)/)
      {
        $b_t = 0; $b_1 = $1; $b_2 = $';
      }
    elsif($b_ =~ /^(\D+)/)
      {
        $b_t = 1; $b_1 = $1; $b_2 = $';
      }

    if($a_t == 0 && $b_t == 0)
      {
        return lexically($a_2,$b_2)
                       if($a_1 == $b_1);
        return $a_1 <=> $b_1;
      }
    if($a_t == 1 && $b_t == 1)
      {
        my $r = lc($a_1) cmp lc($b_1);
        return lexically($a_2,$b_2)
                       if($r == 0);
        return $r;
      }
    return -1
        if($a_t == 0);
    return 1;
  }

sub read_actions
  {
    my $action_file = MusicRoom::File::latest("tag-checks",
                                       look_for => "mtc");
    if(!defined $action_file)
      {
        # Maybe this is the first attempt to process this music
        croak("Cannot find checks to carry out (in tag-checks file)");
      }
    my $ifh = IO::File->new($action_file);
    if(!defined $ifh)
      {
        croak("Cannot open file \"$action_file\"");
      }

    # Parse the action description file
    while(my $line = <$ifh>)
      {
        chomp $line;

        # Read a description of what actions to take
      }
    $ifh->close();
  }

sub ids_where
  {
    my($condition) = @_;

    my @result;
    foreach my $id (sort order_entries keys %tag_data)
      {
        push @result,$id
                if(&{$condition}($tag_data{$id}));
      }
    return @result;
  }

sub define_checks
  {
    # Fixes, that is things we can do to fix values
    %fixes =
      (
        pattern_match_file =>
          {
            # Look for a pattern in the attribute to extract a suitable
            # value
            description => "Use a pattern match on the file name",
            action => sub
              {
                my($ary_ref,$attrib,$pattern) = @_;

                # Fist ask for the pattern to be used, then apply it 
                # to all the missing values and ask for confirmation 
                print "Defining value for $attrib from file name\n\n";
                # Print some eamples
                foreach my $id (@{$ary_ref}[0..5])
                  {
                    next if(!defined $id);
                    print output_columns("File Name:" => 15,
                                         $tag_data{$id}->{file} => 55)."\n";
                  }

                # Enter the pattern
                print "Regular Expression to try: ";
                my $pat = <>;
                chomp $pat;

                return if($pat eq "");

                # process each matching file
                foreach my $id (@{$ary_ref})
                  {
                    my $new_val = "";
                    $new_val = $1
                                  if($tag_data{$id}->{file} =~ /$pat/);
                    next if($new_val eq "");

                    print show_song($id,"Matched Value" => $new_val);
                    my %actions =
                      (
                        a => {description => "Change the $attrib for this song"},
                        x => {description => "Exit from validating"},
                        s => {description => "Skip this song for the moment"},
                      );
                    my $action = select_action("Select an action",%actions);
                    return if($action eq "x");
                    next if($action eq "s");
                    if($action eq "a")
                      {
                        $tag_data{$id}->{$attrib} = $new_val;
                      }
                  }
              },
          },
        pattern_match_dir =>
          {
            # Look for a pattern in the attribute to extract a suitable
            # value
            description => "Use a pattern match on the directory name",
            action => sub
              {
                my($ary_ref,$attrib,$pattern) = @_;

                # Fist ask for the pattern to be used, then apply it 
                # to all the missing values and ask for confirmation 
                print "Defining value for $attrib from dir name\n\n";
                # Print some eamples
                foreach my $id (@{$ary_ref}[0..5])
                  {
                    next if(!defined $id);
                    print output_columns("Dir Name:" => 15,
                                         $tag_data{$id}->{dir} => 55)."\n";
                  }

                # Enter the pattern
                print "Regular Expression to try: ";
                my $pat = <>;
                chomp $pat;

                return if($pat eq "");

                # process each matching file
                foreach my $id (@{$ary_ref})
                  {
                    my $new_val = "";
                    $new_val = $1
                                  if($tag_data{$id}->{dir} =~ /$pat/);
                    next if($new_val eq "");

                    print show_song($id,"Matched Value" => $new_val);
                    my %actions =
                      (
                        a => {description => "Change the $attrib for this song"},
                        x => {description => "Exit from validating"},
                        s => {description => "Skip this song for the moment"},
                      );
                    my $action = select_action("Select an action",%actions);
                    return if($action eq "x");
                    next if($action eq "s");
                    if($action eq "a")
                      {
                        $tag_data{$id}->{$attrib} = $new_val;
                      }
                  }
              },
          },
        diralbum_rules =>
          {
            description => "Apply standard rules to defining directory values",
            action => sub
              {
                my($ary_ref) = @_;

                # Need to find all the items that are in the same directory
                # then the name is either what the majority of them think 
                # with a bias to early track_num values

                my %dir_contents;
                foreach my $id (keys %tag_data)
                  {
                    my $dir = $tag_data{$id}->{dir};
                    $dir_contents{$dir} = {}
                                if(!defined $dir_contents{$dir});

                    if(defined $tag_data{$id}->{dir_album} &&
                               $tag_data{$id}->{dir_album} ne "")
                      {
                        carp("Multiple definitions for dir_album in \"$dir\"")
                             if(defined $dir_contents{$dir}->{dir_album} &&
                                        $dir_contents{$dir}->{dir_album} ne 
                                                   $tag_data{$id}->{dir_album});
                        $dir_contents{$dir}->{dir_album} = 
                                            $tag_data{$id}->{dir_album};
                      }
                    if(defined $tag_data{$id}->{dir_artist} &&
                               $tag_data{$id}->{dir_artist} ne "")
                      {
                        carp("Multiple definitions for dir_artist in \"$dir\"")
                             if(defined $dir_contents{$dir}->{dir_artist} &&
                                        $dir_contents{$dir}->{dir_artist} ne 
                                                   $tag_data{$id}->{dir_artist});
                        $dir_contents{$dir}->{dir_artist} = 
                                            $tag_data{$id}->{dir_artist};
                      }
                    $dir_contents{$dir}->{album} = {}
                            if(!defined $dir_contents{$dir}->{album});
                    $dir_contents{$dir}->{album}->{$tag_data{$id}->{album}} = 0
                            if(!defined $dir_contents{$dir}->{album}->{$tag_data{$id}->{album}});
                    $dir_contents{$dir}->{album}->{$tag_data{$id}->{album}}++;
                    $dir_contents{$dir}->{artist} = {}
                            if(!defined $dir_contents{$dir}->{artist});
                    $dir_contents{$dir}->{artist}->{$tag_data{$id}->{artist}} = 0
                            if(!defined $dir_contents{$dir}->{artist}->{$tag_data{$id}->{artist}});
                    $dir_contents{$dir}->{artist}->{$tag_data{$id}->{artist}}++;
                  }
                foreach my $id (@{$ary_ref})
                  {
                    my $dir = $tag_data{$id}->{dir};
                    if(!defined $tag_data{$id}->{dir_album} ||
                                      $tag_data{$id}->{dir_album} eq "")
                      {
                        my $dir_album = $dir_contents{$dir}->{dir_album};
                        $dir_album = deduce_dir_name(
                                              "album",$dir_contents{$dir})
                                        if(!defined $dir_album);

                        if(!defined $dir_album || $dir_album eq "")
                          {
                            # Need to ask for the name to call these tracks
                            print "Tracks in directory \"$dir\"\n\n";
                            print "Album name for directory: ";
                            my $line = <>;
                            chomp $line;
                            $dir_album = $line;
                          }
                        $dir_contents{$dir}->{dir_album} = $dir_album;

                        $tag_data{$id}->{dir_album} = 
                                    $dir_contents{$dir}->{dir_album};
                      }
                    if(!defined $tag_data{$id}->{dir_artist} ||
                                      $tag_data{$id}->{dir_artist} eq "")
                      {
                        $dir_contents{$dir}->{dir_artist} = deduce_dir_name(
                                              "artist",$dir_contents{$dir})
                                if(!defined $dir_contents{$dir}->{dir_artist});

                        $tag_data{$id}->{dir_artist} = 
                                    $dir_contents{$dir}->{dir_artist};
                      }
                  }
              },
          },
        coverart_missing =>
          {
            # This function won't fix the CSV but it will create
            # a file listing where the program is looking for coverart
            description => "Create a file listing where missing coverart is being looked for",
            action => sub
              {
                my($ary_ref) = @_;

                my $target_file = MusicRoom::File::new_name("$nam-coverart","csv");
                my $ofh = IO::File->new(">$target_file");
                if(!defined $ofh)
                  {
                    carp("Failed to open $target_file for writing");
                    return;
                  }
                my @ca_cols =
                  (
                    "id","artist", "title", "album",
                          "dir_artist", "dir_album","search_list",
                  );
                print $ofh join(',',@ca_cols)."\n";
                foreach my $id (@{$ary_ref})
                  {
                    foreach my $attr (@ca_cols)
                      {
                        print $ofh "," if($attr ne $ca_cols[0]);
                        if($attr eq "search_list")
                          {
                            my @vals = MusicRoom::CoverArt::search_for($tag_data{$id});
                            print $ofh join(',',@vals);
                            next;
                          }
                        print $ofh "\"".$tag_data{$id}->{$attr}."\"";
                      }
                    print $ofh "\n";
                  }
                $ofh->close();
                print "Created list of missing coverart in \"$target_file\"\n";
              },
          },
        coverart_all =>
          {
            # This function won't fix the CSV but it will create
            # a file listing where the program is looking for coverart
            description => "Create a file listing where the coverart is",
            action => sub
              {
                my($ary_ref) = @_;

                my $target_file = MusicRoom::File::new_name("$nam-allcovers","csv");
                my $ofh = IO::File->new(">$target_file");
                if(!defined $ofh)
                  {
                    carp("Failed to open $target_file for writing");
                    return;
                  }
                my @ca_cols =
                  (
                    "id","artist", "title", "album",
                          "dir_artist", "dir_album","src_file","search_list",
                  );
                print $ofh join(',',@ca_cols)."\n";
                foreach my $id (sort order_entries keys %tag_data)
                  {
                    foreach my $attr (@ca_cols)
                      {
                        print $ofh "," if($attr ne $ca_cols[0]);
                        if($attr eq "src_file")
                          {
                            my $val = MusicRoom::CoverArt::locate($tag_data{$id});
                            $val = "" if(!defined $val);
                            print $ofh $val;
                            next;
                          }
                        elsif($attr eq "search_list")
                          {
                            my @vals = MusicRoom::CoverArt::search_for($tag_data{$id});
                            print $ofh join(',',@vals);
                            next;
                          }
                        print $ofh "\"".$tag_data{$id}->{$attr}."\"";
                      }
                    print $ofh "\n";
                  }
                $ofh->close();
                print "Created list of all coverart in \"$target_file\"\n";
              },
          },
        lyrics_missing =>
          {
            # This function won't fix the CSV but it will create
            # a file listing where the program is looking for lyrics
            description => "Create a file listing where lyrics are being looked for",
            action => sub
              {
                my($ary_ref) = @_;

                my $target_file = MusicRoom::File::new_name("$nam-lyrics","csv");
                my $ofh = IO::File->new(">$target_file");
                if(!defined $ofh)
                  {
                    carp("Failed to open $target_file for writing");
                    return;
                  }
                my @ca_cols =
                  (
                    "id","artist", "title", "album",
                          "dir_artist", "dir_album","search_list",
                  );
                print $ofh join(',',@ca_cols)."\n";
                foreach my $id (@{$ary_ref})
                  {
                    foreach my $attr (@ca_cols)
                      {
                        print $ofh "," if($attr ne $ca_cols[0]);
                        if($attr eq "search_list")
                          {
                            my @vals = MusicRoom::Lyrics::search_for($tag_data{$id});
                            print $ofh join(',',@vals);
                            next;
                          }
                        print $ofh "\"".$tag_data{$id}->{$attr}."\"";
                      }
                    print $ofh "\n";
                  }
                $ofh->close();
                print "Created list of missing lyrics in \"$target_file\"\n";
              },
          },
        lyrics_all =>
          {
            # This function won't fix the CSV but it will create
            # a file listing where the program is looking for lyrics
            description => "Create a file listing where the lyric files are",
            action => sub
              {
                my($ary_ref) = @_;

                my $target_file = MusicRoom::File::new_name("$nam-alllyrics","csv");
                my $ofh = IO::File->new(">$target_file");
                if(!defined $ofh)
                  {
                    carp("Failed to open $target_file for writing");
                    return;
                  }
                my @ca_cols =
                  (
                    "id","artist", "title", "album",
                          "dir_artist", "dir_album","src_file","search_list",
                  );
                print $ofh join(',',@ca_cols)."\n";
                foreach my $id (sort order_entries keys %tag_data)
                  {
                    foreach my $attr (@ca_cols)
                      {
                        print $ofh "," if($attr ne $ca_cols[0]);
                        if($attr eq "src_file")
                          {
                            my $val = MusicRoom::Lyrics::locate($tag_data{$id});
                            $val = "" if(!defined $val);
                            print $ofh $val;
                            next;
                          }
                        elsif($attr eq "search_list")
                          {
                            my @vals = MusicRoom::Lyrics::search_for($tag_data{$id});
                            print $ofh join(',',@vals);
                            next;
                          }
                        print $ofh "\"".$tag_data{$id}->{$attr}."\"";
                      }
                    print $ofh "\n";
                  }
                $ofh->close();
                print "Created list of all lyrics in \"$target_file\"\n";
              },
          },
        ask =>
          {
            # Ask for the user to type a value in
            description => "Type in new values",
            action => sub
              {
                my($ary_ref,$attrib,$group_by) = @_;
                my(%global_insert,$id);

                for(my $i=0;$i<=$#{$ary_ref};$i++)
                  {
                    $id = $ary_ref->[$i];
                    if(!defined $tag_data{$id})
                      {
                        carp("Bad ID \"$id\" in validate");
                        next;
                      }
                    if(defined $group_by && $group_by ne "")
                      {
                        my $check = $tag_data{$id}->{$group_by};
                        if(defined $check && $check ne "" && 
                                   defined $global_insert{$check})
                          {
                            $tag_data{$id}->{$attrib} = $global_insert{$check}
                                               if($global_insert{$check} ne "");
                            next;
                          }
                      }

                    print show_song($id);

                    print "Enter $attrib Value (empty line for actions): ";
                    my $line = <>;

                    chomp $line;
                    if($line eq "")
                      {
                        my %actions =
                          (
                            x => {description => "Exit from validating"},
                            s => {description => "Skip this song for the moment"},
                          );
                        if(defined $group_by && $tag_data{$id}->{$group_by})
                          {
                            $actions{i} = {description => 
                                   "Ignore all instances where $group_by equals \"$tag_data{$id}->{$group_by}\""};
                          }
                        my $action = select_action("Select an action",%actions);
                        return if($action eq "x");
                        if($action eq "i")
                          {
                            $global_insert{$tag_data{$id}->{$group_by}} = "";
                          }
                        next;
                      }
                    $tag_data{$id}->{$attrib} = $line;
                    if(defined $group_by && $tag_data{$id}->{$group_by})
                      {
                        $global_insert{$tag_data{$id}->{$group_by}} = $line;
                      }
                  }
              },
          },
        ask_dir =>
          {
            # Ask for the user to type a value in
            description => "Type in new values for a directory at a time",
            action => sub
              {
                my($ary_ref,$attrib,$group_by) = @_;
                my(%dir,$id);

                for(my $i=0;$i<=$#{$ary_ref};$i++)
                  {
                    $id = $ary_ref->[$i];
                    if(!defined $tag_data{$id})
                      {
                        carp("Bad ID \"$id\" in ask");
                        next;
                      }

                    my $dir = $dir{$tag_data{$id}->{dir}};
                    if(defined $dir)
                      {
                        if($dir ne "")
                          {
                            $tag_data{$id}->{$attrib} = $dir;
                          }
                        next;
                      }
                    my $information = "Define value for $attrib\n\n";

                    print show_song($id);

                    print "Enter $attrib Value (empty line for actions): ";
                    my $line = <>;

                    chomp $line;
                    $dir{$tag_data{$id}->{dir}} = $line;
                    $tag_data{$id}->{$attrib} = $line;
                  }
              },
          },
        validate =>
          {
            # Select either to add the existing value to the valid list, or 
            # to pick values from the closest matches
            description => "Pick from matching valid values",
            action => sub
              {
                my($ary_ref,$typ,$attrib) = @_;

                # Have to define these out here, if they are 
                # within the for loop then the goto clears them
                # for some reason
                my(%global_replace,$local_edit,$val,$id);

                for(my $i=0;$i<=$#{$ary_ref};$i++)
                  {
                    $local_edit = "";
                    $id = $ary_ref->[$i];
                    if(!defined $tag_data{$id})
                      {
                        carp("Bad ID \"$id\" in validate");
                        next;
                      }
                    $val = $tag_data{$id}->{$attrib};
                    if(!defined $val)
                      {
                        carp("Bad attribute name \"$attrib\" in validate (for $id)");
                        next;
                      }

                    if(defined $global_replace{$val})
                      {
                        if($global_replace{$val} ne "")
                          {
                            $tag_data{$id}->{$attrib} = $global_replace{$val};
                          }
                        next;
                      }

try_again:
                    my $test = $val;
                    $test = $local_edit if($local_edit ne "");

                    my @extra_info;
                    my $nearest;
                    if($typ eq "artist")
                      {
                        $nearest = MusicRoom::ValidArtists::nearest(
                                        $test,"edit tags",1);
                      }
                    elsif($typ eq "album")
                      {
                        $nearest = MusicRoom::ValidAlbums::nearest(
                                        $test,"edit tags",1);
                      }
                    elsif($typ eq "title")
                      {
                        $nearest = MusicRoom::ValidSongs::nearest(
                                        $test,"edit tags",1);
                      }
                    else
                      {
                        carp("Unknown validation category \"$typ\"");
                        next;
                      }

                    if(!defined $nearest)
                      {
                        # There is no name that we can find near this one
                        $nearest = "";
                      }
                    else
                      {
                        if(lc($nearest) eq lc($val))
                          {
                            $tag_data{$id}->{$attrib} = $nearest;
                          }
                      }

                    my @values = ("Currently" => $val);

                    my %actions =
                      (
                         v => {description => "Add \"$val\" as a valid $typ"},
                         s => {description => "Skip this song for the moment"},
                         i => {description => "Ignore all instances where $attrib equals \"$val\""},
                         e => {description => "Enter a value to try matching"},
                         x => {description => "Exit from validating"},
                      );
                    if($local_edit ne "")
                      {
                        push @values,"Tried" => $local_edit;
                        $actions{u} = 
                            {description => "Use edit value for this one song"};
                        $actions{y} = 
                            {description => "Use edit value for this and matching songs"};                        
                      }
                    if($nearest ne "")
                      {
                        push @values,"Matches" => $nearest;
                        $actions{1} = 
                            {description => "Use the matching value for this one song"};
                        $actions{a} = 
                            {description => "Use the matching value for this and matching songs"};
                      }

                    print show_song($id,@values);
                    my $action = select_action("Select action",%actions);

                    if($action eq "e")
                      {
                        print "Name to try: ";
                        $local_edit = <>;
                        chomp $local_edit;
                        goto try_again;
                      }
                    return if($action eq "x");

                    if($action eq "v")
                      {
                        if($typ eq "artist")
                          {
                            MusicRoom::ValidArtists::add($val);
                          }
                        elsif($typ eq "album")
                          {
                            MusicRoom::ValidAlbums::add($val);
                          }
                        elsif($typ eq "title")
                          {
                            MusicRoom::ValidSongs::add($val);
                          }
                        $global_replace{$val} = "";
                      }

                    $global_replace{$val} = "" 
                                     if($action eq "i");

                    $tag_data{$id}->{$attrib} = $nearest
                                     if($action eq "1" || $action eq "a");
                    $global_replace{$val} = $nearest
                                     if($action eq "a");
                  }
                # This should be in the routine
              },
          },
        closest_song_hit =>
          {
            # Look in the list of hits from this artist and pick a value from there
            description => "Pick from the artist's hit songs",
            action => sub
              {
                my($ary_ref,$attrib) = @_;
                foreach my $id (@{$ary_ref})
                  {
                    my(@hits) = MusicRoom::Charts::entries("song",$tag_data{$id}->{artist});
                    next if(!@hits);

                    my $title = $tag_data{$id}->{title};

                    my @top_match;

                    my %actions =
                      (
                        x => {description => "Exit from validating"},
                        s => {description => "Skip this song for the moment"},
                      );

                    my $count = 1;
                    my $sort_fun = sub {return 
                             MusicRoom::Text::Nearest::_closeness($title,$a) <=>
                             MusicRoom::Text::Nearest::_closeness($title,$b);};
                    foreach my $possible (sort $sort_fun @hits)
                      {
                        last if(!defined $possible || $possible eq "" ||
                                $count > 6);

                        $actions{$count} = {description => $possible};
                        push @top_match,$possible;
                        $count++;
                      }
                    print show_song($id);

                    my $action = select_action("Select an action",%actions);
                    return if($action eq "x");
                    next if($action eq "s");
                    if($action =~ /^\d+$/)
                      {
                        $tag_data{$id}->{title} = $top_match[$action-1];
                      }
                  }
              },
          },
        closest_album_hit =>
          {
            # Look in the list of hits from this artist and pick a value from there
            description => "Pick from the artist's hit albums",
            action => sub
              {
                my($ary_ref,$attrib) = @_;
                foreach my $id (@{$ary_ref})
                  {
                    my(@hits) = MusicRoom::Charts::entries("album",$tag_data{$id}->{artist});
                    next if(!@hits);

                    my $title = $tag_data{$id}->{title};

                    my @top_match;

                    my %actions =
                      (
                        x => {description => "Exit from validating"},
                        s => {description => "Skip this song for the moment"},
                      );

                    my $count = 1;
                    my $sort_fun = sub {return 
                             MusicRoom::Text::Nearest::_closeness($title,$a) <=>
                             MusicRoom::Text::Nearest::_closeness($title,$b);};
                    foreach my $possible (sort $sort_fun @hits)
                      {
                        last if(!defined $possible || $possible eq "" ||
                                $count > 6);

                        $actions{$count} = {description => $possible};
                        push @top_match,$possible;
                        $count++;
                      }
                    print show_song($id);

                    my $action = select_action("Select an action",%actions);
                    return if($action eq "x");
                    next if($action eq "s");
                    if($action =~ /^\d+$/)
                      {
                        $tag_data{$id}->{album} = $top_match[$action-1];
                      }
                  }
              },
          },
        song_hit_year =>
          {
            # Look in the list of hits from this artist and pick a value from there
            description => "Pick the song from the artist's hits",
            action => sub
              {
                my($ary_ref,$attrib) = @_;
                my %dir;

                foreach my $id (@{$ary_ref})
                  {
                    if(defined $dir{$tag_data{$id}->{dir}})
                      {
                        $tag_data{$id}->{year} = $dir{$tag_data{$id}->{dir}};
                        next;
                      }

                    my $tag_year = $tag_data{$id}->{year};

                    my $song_year = MusicRoom::Charts::year("song",
                                          $tag_data{$id}->{artist},$tag_data{$id}->{title});
                    $song_year = "" if(!defined $song_year || $song_year eq "unknown");

                    my $album_year = MusicRoom::Charts::year("album",
                                          $tag_data{$id}->{artist},$tag_data{$id}->{album});
                    $album_year = "" if(!defined $album_year || $album_year eq "unknown");

                    next if($tag_year eq "" && $song_year eq "" && $album_year eq "");

                    my @values;

                    my %actions =
                      (
                        x => {description => "Exit from validating"},
                        s => {description => "Skip this song for the moment"},
                      );

                    if($tag_year ne "")
                      {
                        $actions{t} = {description => "Stay with tag year"};
                        push @values,"Tag Year" => $tag_year;
                      }
                    if($song_year ne "")
                      {
                        push @values,"Song Year" => $song_year;
                        $actions{h} = {description => "Change to hit year of song"};
                        $actions{d} = {description => "Change all songs in dir to hit year of song"};
                      }
                    if($album_year ne "")
                      {
                        push @values,"Album Year" => $album_year;
                        $actions{a} = {description => "Change to hit year of album"};
                        $actions{l} = {description => "Change all songs in dir to hit year of song"};
                      }

                    print show_song($id,@values);

                    my $action = select_action("Select an action",%actions);

                    return if($action eq "x");
                    next if($action eq "s");
                    $tag_data{$id}->{year} = $song_year
                                                      if($action eq "h" || $action eq "d");
                    $tag_data{$id}->{year} = $album_year
                                                      if($action eq "a" || $action eq "l");
                    $dir{$tag_data{$id}->{dir}} = $song_year
                                                      if($action eq "d");
                    $dir{$tag_data{$id}->{dir}} = $album_year
                                                      if($action eq "l");
                  }
              },
          },
      );

    # Now lets find the highest priority actions
    %checks =
      (
        # nonempty_id, if this flag was true then everything would be screwed
        nonempty_format =>
          {
            # The description describes what is wrong
            description => 'Some format attributes are empty',

            # This is how we get a list of IDs that dont fulfill the criteria
            test => sub
              {
                return ids_where(sub {$_[0]->{original_format} eq ""});
              },

            # Here are the options of how to fix the issue
            fixes => 
              [
                pattern_match_file => ["format",'\.([^\.]+)$'],
                ask => ["format"],
                ask_dir => ["format"],
              ],
          },
        nonempty_artist =>
          {
            description => 'Some artist names are empty',
            requires => ['nonempty_format'],
            test => sub
              {
                return ids_where(sub {$_[0]->{artist} eq ""});
              },
            fixes => 
              [
                pattern_match_file => ["artist"],
                pattern_match_dir => ["artist"],
                # Ask based on playing the track
                # Other artists in the same dir?
                ask => ["artist"],
                ask_dir => ["artist"],
              ],
          },
        nonempty_title =>
          {
            description => 'Some song titles are empty',
            requires => ['valid_artist'],
            test => sub
              {
                return ids_where(sub {$_[0]->{title} eq ""});
              },
            fixes => 
              [
                pattern_match_file => ["title"],
                ask => ["title"],
              ],
          },
        nonempty_album =>
          {
            description => 'Some album names are empty',
            requires => ['valid_artist'],
            test => sub
              {
                return ids_where(sub {$_[0]->{album} eq ""});
              },
            fixes => 
              [
                pattern_match_dir => ["album"],
                pattern_match_file => ["album"],
                ask => ["album"],
                ask_dir => ["album"],
              ],
          },

        valid_artist =>
          {
            description => 'Some artist names are not on the valid list',
            requires => ['nonempty_artist'],
            test => sub
              {
                return ids_where(sub 
                  {
                    my($tag_record) = @_;
                    my $near = MusicRoom::ValidArtists::nearest(
                                        $tag_record->{artist},"edit tags",1);
                    return 1 if(!defined $near);
                    return ($tag_record->{artist} ne $near);
                  });
              },
            show_example => sub
              {
                my @examples = pick_examples(valid_artist => 3,"artist");
                return "" if(!@examples);

                return format_examples(\@examples,
                                artist => 20, title => 22, 
                                album => 15);
              },
            fixes => 
              [
                validate => ["artist","artist"],
                pattern_match_dir => ["artist"],
                pattern_match_file => ["artist"],
                ask => ["artist"],
                ask_dir => ["artist"],
              ],
          },
        valid_title =>
          {
            description => 'Some song titles are not on the valid list',
            requires => ['valid_artist','nonempty_title'],
            test => sub
              {
                return ids_where(sub 
                  {
                    my($test_title) = @_;
                    my $near = MusicRoom::ValidSongs::nearest(
                                        $test_title->{title},"edit tags",1);
                    return 1 if(!defined $near);
                    return $test_title->{title} ne $near;
                  });
              },
            fixes => 
              [
                closest_song_hit => ["title"],
                validate => ["title","title"],
                pattern_match_dir => ["title"],
                pattern_match_file => ["title"],
                ask => ["title"],
              ],
          },
        valid_album =>
          {
            description => 'Some album names are not on the valid list',
            requires => ['valid_artist','nonempty_album'],
            test => sub
              {
                return ids_where(sub 
                  {
                    my($test_album) = @_;
                    my $near = MusicRoom::ValidAlbums::nearest(
                                        $test_album->{album},"edit tags",1);
                    return 1 if(!defined $near);
                    return $test_album->{album} ne $near;
                  });
              },
            fixes => 
              [
                closest_album_hit => ["album"],
                validate => ["album","album"],
                pattern_match_dir => ["album"],
                pattern_match_file => ["album"],
                ask => ["album"],
                ask_dir => ["album"],
              ],
          },

        nonempty_dirartist =>
          {
            description => 'Some directory artist names are empty',
            requires => ['valid_artist', 'valid_title', 'valid_album'],
            test => sub
              {
                return ids_where(sub {$_[0]->{dir_artist} eq ""});
              },
            fixes => 
              [
                diralbum_rules => [],
                pattern_match_dir => ["dir_artist"],
                ask_dir => ["dir_artist","dir"],
              ],
          },
        nonempty_diralbum =>
          {
            description => 'Some directory album names are empty',
            requires => ['valid_artist', 'valid_title', 'valid_album'],
            test => sub
              {
                return ids_where(sub {$_[0]->{dir_album} eq ""});
              },
            fixes => 
              [
                diralbum_rules => [],
                pattern_match_dir => ["dir_album"],
                ask_dir => ["dir_album","dir"],
              ],
          },
        valid_dirartist =>
          {
            description => 'Some directory artist names are not on the valid list',
            requires => ['valid_artist', 'valid_title', 
                         'valid_album', 'nonempty_dirartist'],
            test => sub
              {
                return ids_where(sub 
                  {
                    my($tag_record) = @_;
                    my $near = MusicRoom::ValidArtists::nearest(
                                        $tag_record->{dir_artist},"edit tags",1);
                    return 1 if(!defined $near);
                    return ($tag_record->{dir_artist} ne $near);
                  });
              },
            fixes => 
              [
                validate => ["artist","dir_artist"],
                pattern_match_dir => ["dir_artist"],
                ask_dir => ["dir_artist","dir"],
              ],
          },
        valid_diralbum =>
          {
            description => 'Some directory album names are not on the valid list',
            requires => ['valid_artist', 'valid_title', 
                         'valid_album', 'nonempty_diralbum'],
            test => sub
              {
                return ids_where(sub 
                  {
                    my($tag_record) = @_;
                    my $near = MusicRoom::ValidAlbums::nearest(
                                        $tag_record->{dir_album},"edit tags",1);
                    return 1 if(!defined $near);
                    return ($tag_record->{dir_album} ne $near);
                  });
              },
            fixes => 
              [
                validate => ["album","dir_album"],
                pattern_match_dir => ["dir_album"],
                ask_dir => ["dir_album","dir"],
              ],
          },

        invalid_tracknum =>
          {
            description => 'Some track numbers are invalid',
            requires => ['valid_artist', 'valid_title', 'valid_album'],
            level => 'required',
            test => sub
              {
                return ids_where(sub 
                  {
                    my($tag_record) = @_;
                    my $track_num = $tag_record->{track_num};
                    return 1 if(!defined $track_num || $track_num eq "");
                    return 1 if($track_num =~ /\D/);
                    return "";
                  });
              },
            fixes => 
              [
                # How do we fix track numbers?
                pattern_match_file => ["track_num"],
                ask => ["track_num"],
              ],
          },
        nonunique_tracknum =>
          {
            description => 'There are some clashing track numbers',
            requires => ['nonempty_tracknum'],
            level => 'advisory',
            test => sub
              {
                my %track_nums;

                foreach my $id (keys %tag_data)
                  {
                    my $dir = $tag_data{$id}->{dir};
                    my $track_num = $tag_data{$id}->{track_num};

                    $track_nums{$dir} = {} if(!defined $track_nums{$dir});
                    if(defined $track_nums{$dir}->{$track_num})
                      {
                        # We have a clash
                        push @{$track_nums{$dir}->{$track_num}},$id;
                      }
                    else
                      {
                        $track_nums{$dir}->{$track_num} = [$id];
                      }
                  }
                my @ret;
                foreach my $dir (sort lexically keys %track_nums)
                  {
                    foreach my $track_num (sort lexically keys %{$track_nums{$dir}})
                      {
                        push @ret,@{$track_nums{$dir}->{$track_num}}
                               if($#{$track_nums{$dir}->{$track_num}} > 0);
                      }
                  }
                return @ret;
              },
            fixes => 
              [
                # How do we fix track numbers?
                pattern_match_file => ["track_num"],
                ask => ["track_num"],
              ],
          },

        invalid_length =>
          {
            description => 'Some track length tags are invalid',
            requires => ['valid_artist', 'valid_title', 'valid_album'],
            test => sub
              {
                return ids_where(sub 
                  {
                    my($tag_record) = @_;
                    return 1 if(!defined $tag_record->{length_secs});
                    if($tag_record->{length_secs} =~ /^\d+$/)
                      {
                        return 1 if($tag_record->{length_secs} == 0);
                        return "";
                      }
                    else
                      {
                        return 1;
                      }
                  });
              },
            fixes => 
              [
                # How do we fix track lengths?
                ask => ["length_secs"],
              ],
          },
        invalid_year =>
          {
            description => 'Some year tags are invalid',
            requires => ['valid_artist', 'valid_title', 'valid_album'],
            test => sub
              {
                return ids_where(sub 
                  {
                    my($tag_record) = @_;
                    my $year = $tag_record->{year};
                    return 1 if(!defined $year || $year eq "");
                    return 1 if($year =~ /\D/);

                    # Only accept years between 900AD and 2050
                    # that should be reasonable for most purposes
                    # (when processing your time machine's mp3
                    #             playlist you may need to alter this)
                    return 1 if($year < 900 || $year > 2050);
                    return "";
                  });
              },
            fixes => 
              [
                # How do we fix track numbers?
                song_hit_year => [],
                pattern_match_file => ["year"],
                pattern_match_dir => ["year"],
                ask => ["year"],
                ask_dir => ["year"],
              ],
          },
        questionable_year =>
          {
            description => 'The suggested year for some tracks could be incorrect',
            requires => ['invalid_year'],
            level => 'advisory',
            test => sub
              {
                return ids_where(sub 
                  {
                    my($tag_record) = @_;
                    my $tag_year = $tag_record->{year};
                    my $chart_year = MusicRoom::Charts::year("song",
                                          $tag_record->{artist},$tag_record->{title});
                    if(!defined $chart_year || $chart_year eq "unknown")
                      {
                        $chart_year = MusicRoom::Charts::year("album",
                                          $tag_record->{artist},$tag_record->{album});
                      }
                    return "" if(!defined $chart_year || $chart_year eq "" || 
                                                         $chart_year eq "unknown");
                    return "" if(abs($chart_year - $tag_year) < 3);
                    return 1;
                  });
              },
            fixes => 
              [
                # How do we fix track numbers?
                song_hit_year => [],
                pattern_match_file => ["year"],
                pattern_match_dir => ["year"],
                ask => ["year"],
                ask_dir => ["year"],
              ],
          },

        # If this is a duplicate of a whole album we already have
        # we may want to ignore it
        duplicate_album =>
          {
            description => 'Some albuma are already in the collection',
            requires => ['valid_artist', 'valid_album'],
            level => 'disabled',
          },

        # If this is a duplicate of a track we already have then 
        # we may want to give the user the chance to ignore it
        duplicate_track =>
          {
            description => 'Some songs are already in the collection',
            requires => ['valid_artist', 'valid_title', 'valid_album'],
            level => 'disabled',
          },

        # If the cover art is not yet available we probably want to 
        # go look for it
        missing_cover =>
          {
            description => 'Some cover art is not yet available',
            requires => ['valid_artist', 'valid_title', 'valid_album', 
                         'valid_dirartist','valid_diralbum'],
            level => 'advisory',
            test => sub
              {
                return ids_where(sub 
                  {
                    my($tag_record) = @_;

                    # The locate function works with either a real track
                    # or with a hash that happens to have the right 
                    # attribute names (which, by coincidence is what we have)
                    my $val = MusicRoom::CoverArt::locate($tag_record);
                    return "" if(defined $val && $val ne "");
                    return 1;
                  });
              },
            fixes => 
              [
                # There is no way to fix this within the CSV file,
                # but we can have a magic fixer that creates a list 
                # of the cover images we need
                coverart_missing => [],
                coverart_all => [],
              ],
          },

        # If the lyrics are not available we might want to look for them
        missing_lyrics =>
          {
            description => 'Some lyrics have not yet been fetched',
            requires => ['valid_artist', 'valid_title', 'valid_album', 
                         'valid_dirartist','valid_diralbum'],
            level => 'advisory',
            test => sub
              {
                return ids_where(sub 
                  {
                    my($tag_record) = @_;

                    # The locate function works with either a real track
                    # or with a hash that happens to have the right 
                    # attribute names (which, by coincidence is what we have)
                    my $val = MusicRoom::Lyrics::locate($tag_record);
                    return "" if(defined $val && $val ne "");
                    return 1;
                  });
              },
            fixes => 
              [
                # There is no way to fix this within the CSV file,
                # but we can have a magic fixer that creates a list 
                # of the cover images we need
                lyrics_missing => [],
                lyrics_all => [],
              ],
          },

        define_genre =>
          {
            description => 'Some songs have not been assigned a genre',
            requires => ['valid_artist', 'valid_title', 'valid_album'],
            level => 'disabled',
          },

        # What else might we want to do?
        #
        #    Grab a page from Wikipedia/ RYM/ last.fm?
        #    Generate some playlists
        #    Categorise the genre of the tracks
        #    Give a personal star rating for the track
        #

        # Getting here indicates that all the mandatetory tests have 
        # been passed and we are ready to import the data into the 
        # collection
        notfinalised =>
          {
            description => 'The validated tag set can now be saved',
            requires => ['invalid_year', 'invalid_tracknum', 
                         'valid_diralbum', 'valid_dirartist',
                        ],

            # This test *always* returns a complete list of IDs
            test => sub {return $_[0]->{id}},
            fixes => 
              [
                finalise => [],
              ],
          },
      );
  }

sub show_song
  {
    my($id,@vals) = @_;

    my $information = "Current Values\n\n";

    foreach my $show_attrib ("artist","title",
                                  "album","dir","file")
      {
        $information .= output_columns(" "x(14 - length($show_attrib)) . 
                                                     "\u${show_attrib}:" => 15,
                               $tag_data{$id}->{$show_attrib} => 55)."\n";
      }

    $information .= "\n";
    for(my $i=0;$i<=$#{vals};$i+=2)
      {
        my $show_attrib = $vals[$i];
        my $val = $vals[$i+1];

        $information .= output_columns(" "x(14 - length($show_attrib)) . 
                                                     "\u${show_attrib}:" => 15,
                                              $val => 55)."\n";
      }
    $information .= "\n";

    return $information;
  }

sub current_issues
  {
    # Build a dependancy tree based on the prerequisites for each 
    # test and return a list of issues that need addressing at the moment
    my %state;
    %failed_ids = ();

    while(1)
      {
        my $something_changed = 0;
        foreach my $test (keys %checks)
          {
            my $prereq_ready = 1;

            # If we know about this one move on
            next if(defined $state{$test});

            if(defined $checks{$test}->{level} && 
                         $checks{$test}->{level} eq "disabled")
              {
                $state{$test} = "passed";
                $something_changed = 1;
                next;
              }

            if(defined $checks{$test}->{requires})
              {
                foreach my $prereq (@{$checks{$test}->{requires}})
                  {
                    if(defined $state{$prereq} && 
                            ($state{$prereq} eq "failed" || $state{$prereq} eq "wait"))
                      {
                        # One of the prerequisites needs clearing 
                        # up before we can do this one
                        $state{$test} = "wait";
                        $something_changed = 1;
                        last;
                      }
                    elsif(!defined $state{$prereq} ||
                                    $state{$prereq} ne "passed")
                      {
                        $prereq_ready = "";
                        last;
                      }
                  }
              }

            # If the prereqs are not yet fully resolved move on
            next if(!$prereq_ready);

            if(!defined $state{$test})
              {
                # Since we don't have a defined state 
                # we must be ready to run the test for this one
                if(!defined $checks{$test}->{test})
                  {
                    carp("Cannot find test for $test");
                    $state{$test} = "wait";
                    $something_changed = 1;
                    next;
                  }
                my @failed = &{$checks{$test}->{test}}();
                if(@failed)
                  {
                    # We have a list of IDs that failed
                    $state{$test} = "failed";
                    $something_changed = 1;
                    $failed_ids{$test} = \@failed;
                  }
                else
                  {
                    # We passed everything
                    $state{$test} = "passed";
                    $something_changed = 1;
                  }
              }
          }

        # If we get to the end and nothing 
        last if(!$something_changed);
      }

    # The sort here is a tad meaningless, however it does ensure 
    # a consistent ordering of the tasks to do, and since there 
    # should only be a few options at any point in the process
    # it shouldn't impose too much surprise on the users
    my @failed_tests;

    foreach my $test (sort keys %state)
      {
        if($state{$test} eq "failed")
          {
            # This test failed, so we have to deal with it at this 
            # point.

            push @failed_tests,$test;
          }
      }

    return @failed_tests;
  }
sub pick_examples
  {
    my($issue,$max_count,$field) = @_;

    return ()
        if(!defined $failed_ids{$issue});

    if(ref($failed_ids{$issue}) ne "ARRAY")
      {
        carp("List of failed ids should be an array");
        return ();
      }
    if($max_count <= 0)
      {
        carp("Max count must be a positive integer (not \"$max_count\")");
        return ();
      }
    # Because we may be looking for a particular field we have to
    # process this the old-fashioned way
    my $count = 0;
    my %found_values;
    my @ret;

    foreach my $id (@{$failed_ids{$issue}})
      {
        if(!defined $field || 
             !defined $found_values{$tag_data{$id}->{$field}})
          {
            $found_values{$tag_data{$id}->{$field}} = 1;
            push @ret,$id;
            $count++;
            last if($count >= $max_count);
          }
      }
    return @ret;
  }

sub output_columns
  {
    my(@values) = @_;

    my $line_start = "    ";
    my $between_items = " ";
    my $line_end = "";

    my @output;

    for(my $i=0;$i<=$#values;$i+=2)
      {
        my($val,$width) = @values[$i,$i+1];

        if($val eq "_line_start_")
          {
            $line_start = $width;
            next;
          }
        elsif($val eq "_between_items_")
          {
            $between_items = $width;
            next;
          }
        elsif($val eq "_line_end_")
          {
            $line_end = $width;
            next;
          }
        if(length($val) < $width)
          {
            $val .= " "x($width - length($val));
          }
        elsif(length($val) > $width)
          {
            $val = substr($val,0,$width-3)."...";
          }
        push @output,$val;
      }

    return $line_start.join($between_items,@output).$line_end;
  }

sub format_examples
  {
    my($ary_ref,@fields) = @_;

    my @output;
    for(my $i=0;$i<=$#{$ary_ref};$i++)
      {
        # Print a single line
        my @vals;
        my $id = $ary_ref->[$i];
        for(my $field=0;$field<=$#fields;$field+=2)
          {
            my $val = $tag_data{$id}->{$fields[$field]};
            if(!defined $val)
              {
                carp("Cannot find value for $fields[$field] in track $id");
                $val = "";
              }
            push @vals,$val,$fields[$field+1];
          }
        $output[$i] = output_columns(@vals);
      }

    return join("\n",@output);
  }

sub deduce_dir_name
  {
    my($field,$dir_data) = @_;

    my $vote_total = 0;
    my($biggest_count,$biggest_val);

    foreach my $val (keys %{$dir_data->{$field}})
      {
        next if($val eq "");

        $vote_total += $dir_data->{$field}->{$val};
        if(!defined $biggest_count ||
                    $biggest_count < $dir_data->{$field}->{$val})
          {
            $biggest_count = $dir_data->{$field}->{$val};
            $biggest_val = $val;
          }
      }
    return $biggest_val
                      if($vote_total == 1);

    if($vote_total > (($biggest_count * 2) - 1))
      {
        # There is no one contributor that has more than 50%
        if($field eq "album")
          {
            return "";
          }
        elsif($field eq "artist")
          {
            return "Various Artists";
          }
        else
          {
            carp("Cannot find suitable name for $field");
            return "";
          }
      }
    return $biggest_val;
  }

