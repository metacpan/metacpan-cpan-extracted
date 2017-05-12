# Find similar names grouped by categories

=head1 NAME

MusicRoom::Text::Nearest - Select the closest matching names

=head1 DESCRIPTION

When handling music tags you often find that variations in spelling and 
interpretation make it difficult to identify matchs.  For example are these
two tracks the same?

    The Sugarhill Gang - Rapper's Delight (reentry)
    Sugar Hill Gang - The Rappers Delight (2)

The module uses a number of techniques (implemented in modules like
MusicRoom::Text::SoundexNG and Text::WagnerFischer) to identify "nearby" values that 
it can suggest.

Here is an example of how to use the module:

    use MusicRoom::Text::Nearest;
    MusicRoom::Text::Nearest::add_categories(
        artist => 1,
        song => 
          {
            qualifiers => ['\s*\(1\)', '\s*\(2\)', '\s*\(3\)',
                           '\s*\(remix\)', '\s*\(re\-entry\)', '\s*\(re\-issue\)', 
                           '\s*\(live\)',],
          },
      );
    my $fh = IO::File->new("valid-artists.txt");
    MusicRoom::Text::Nearest::read_names($fh,"artist");
    $fh->close();

    my $artist = "Sugar Hill Gang";
    my $real_artist = MusicRoom::Text::Nearest::get("artist",$artist,"Checking artists");

This adds the categories "artist" and "song" to the valid sets.  The qualifiers
flag tells the module to ignore certain strings in the song names.  Then we read 
a file containing the valid names.  Finally we select the closest one of those
to use as the name of the artist.

Of course this module won't help identify that "The Plastic Ono Band" and 
"John Lennon" are the same, that you have to do for yourself.

=head1 FORMAT

The module depends on being seeded with a good set of valid entries.  This 
is normally done by reading a file containing a list of values.  These files
are in a particular format, here is an example:

    # 1        -> src-tracks
    #  1       -> uk single
    #   1      -> uk totp
    #    1     -> au yearsong
    #     1    -> de decadesong
    #      1   -> us yearsong
    #       1  -> us riaaalbum
    #        1 -> nl single
    
     { X  1  4} Jason Donovan
     { 1      } Jason Downs
     {        } Jason Falkner
     {1    1  } Jason Mraz

There are two types of comments here, lines starting with hash are considered 
to be comments, entries between curly brackets are ignored as well.  These allow
the files to keep track of the source of the names (in the above example we 
have files called "src-tracks", "uk single" and so on with the numbers giving 
an indication of the count of those items in that file, so "Jason Donovan" is 
in "uk single" more than 9 times, in "de decadesong" once and in "nl single" 
four times.

Neither type of comment is necessary for the module, however they do make it 
easier to see where the names came from.  This makes managing 
the names easier (or indeed possible).

=cut

package MusicRoom::Text::Nearest;

use strict;
use warnings;

use IO::File;
use Carp;
use MusicRoom;
use MusicRoom::Text::SoundexNG;
use Text::LevenshteinXS;
use Data::Dumper;

my %valid_categories = ();

my %sdx_solo;
my %sdx_one;
my %sdx_two;
my %sdx_join;
my %sdx_nearby;

my %id2str;
my %seen;
my %rename;
my %qualifiers;

my $score_all    = 1000000;
my $score_one    = 100000;
my $score_two    = 200000;
my $score_join   = 40000;
my $score_nioj   = 40000;
my $score_nearby = 10000;
my $max_hash_array = 200;

my $verbose = 0;
my $dont_regenerate_nearby_tables = 0;

# These two control how close we have to be to map
my $score_ratio = 5.0;
# my $score_proportion = 0.4;
my $sdx_ratio = 4.0;

my $error_function;

MusicRoom::Text::SoundexNG::ignore_words("ost","ep");
MusicRoom::Text::SoundexNG::add_mappings(
    '\bwanna\b' => "want to", with => "&", featuring => "&", '\bya\b' => 'your',
    '\boutta\b' => "out of",
  );

=head2 list($category)

List all the names registered in a particular category

=cut

sub list
  {
    # Provide an ordered list of the valid items in a category
    my($cat) = @_;
    
    if(!defined $valid_categories{$cat})
      {
        carp("Category $cat not defined\n");
        return undef;
      }

    return () if(!defined $seen{$cat});

    my @list;
    foreach my $val (sort by_soundex @{$id2str{$cat}})
      {
        push @list,$val;
      }
    return @list;
  }

=head2 by_soundex($a,$b)

A sort routine that works by SoundexNG.  Pretty much useless outside the 
module because of the scoping rules for $a and $b.  

=cut

sub by_soundex
  {
    # Sort routine so $a & $b have magic meanings!

    # Also this is working on the keys of the hash, not the real values
    # however at the moment the keys are just lower case versions of 
    # the strings, so that will work
    my $sdx_a = MusicRoom::Text::SoundexNG::soundex($a);
    my $sdx_b = MusicRoom::Text::SoundexNG::soundex($b);

    return _lexically($a,$b)
               if($sdx_a eq $sdx_b);
    return $sdx_a cmp $sdx_b;
  }

=head2 add_handler($fun,$args)

Add an error handler to be called when an error is encountered in the module.

   sub found_error
     {
       my($str) = @_;
       print STDERR $str;
     }

    MusicRoom::Text::Nearest::add_handler(\&found_error);

=cut

sub add_handler
  {
    my($fun,$args) = @_;

    $error_function = [$fun,$args];
  }

=head2 error($str)

This invokes an error in the module.  I can't see why anyone should want to 
call this outside the module.

=cut

sub error
  {
    if(defined $error_function)
      {
        &{$error_function->[0]}($error_function->[1],@_);
      }
    else
      {
        print STDERR $_[0] . "\n";
      }
  }

=head2 add_categories(%categories)

Add a set of categories.  This can be called like:

    MusicRoom::Text::Nearest::add_categories(
        artist => 1,
        song => 
          {
            qualifiers => ['\s*\(1\)', '\s*\(2\)', '\s*\(3\)',
                           '\s*\(remix\)', '\s*\(re\-entry\)', '\s*\(re\-issue\)', 
                           '\s*\(live\)',],
          },
      );

If a hash is passed it is treated as a set of flags controlling the category.
Currently "qualifiers" is the only handled flag.
    
=cut

sub add_categories
  {
    my(%cats) = @_;

    my %source_file;
    my %save_cache;

    foreach my $cat (keys %cats)
      {
        $valid_categories{$cat} = 1;

        $id2str{$cat} = [];
        $seen{$cat} = {};
        $rename{$cat} = {};

        $sdx_solo{$cat} = {};
        $sdx_nearby{$cat} = {};
        $sdx_one{$cat} = {};
        $sdx_two{$cat} = {};
        $sdx_join{$cat} = {};

        next if(ref($cats{$cat}) ne "HASH");

        foreach my $key (keys %{$cats{$cat}})
          {
            if($key eq "qualifiers")
              {
                $qualifiers{$cat} = $cats{$cat}->{$key};
              }
            elsif($key eq "save_cache")
              {
                $save_cache{$cat} = $cats{$cat}->{$key};
              }
            elsif($key eq "from_file")
              {
                $source_file{$cat} = $cats{$cat}->{$key};
              }
            else
              {
                # Unknown categorry qualifier 
                carp("Unknown category qualifier $key\n");
              }
          }
      }
    # Finally read the values if we have a file
    foreach my $cat (keys %source_file)
      {
        my $file_name = $source_file{$cat};

        # Can we read this from the cache?
        if(!read_cache($cat,$file_name))
          {
            my $fh = IO::File->new($file_name);
            read_names($fh,$cat);
            $fh->close();

            _compute_nearby();

            save_cache($cat) 
                 if(defined $save_cache{$cat} && $save_cache{$cat});
          }
      }
  }

=head2 add_name($category,$name)

Add a new valid name into the category.

=cut

sub add_name
  {
    my($cat,$name) = @_;
    
    if(!defined $valid_categories{$cat})
      {
        carp("Category $cat not defined\n");
        return undef;
      }
    if(defined $seen{$cat}->{lc($name)})
      {
        carp("$cat \"$name\" conflicts with \"".
               $id2str{$cat}->[$seen{$cat}->{lc($name)}]."\"\n");
        return undef;
      }
    if(defined $rename{$cat}->{lc($name)})
      {
        carp("$cat \"$name\" is already mapped to \"".
               $id2str{$cat}->[$rename{$cat}->{lc($name)}]."\"\n");
        return get($cat,$name,"add_name call");
      }

    # Save the capitalisation
    push @{$id2str{$cat}},$name;
    my $id = $#{$id2str{$cat}};
    $seen{$cat}->{lc($name)} = $id;

    # Get the Soundex string for the name
    my $sdx_str = MusicRoom::Text::SoundexNG::soundex($name);

    # Remember it in our list of Soundex strings
    _add_target($sdx_solo{$cat},$sdx_str,$id);

    # Split the Soundex into words
    my @sdx = split(/[\s_]+/,$sdx_str);

    for(my $i=0;$i<=$#sdx;$i++)
      {
        my $one = $sdx[$i];
        _add_target($sdx_one{$cat},$one,$id);

        # Create one entries by concatenating single soundex elements
        for(my $j=1;$j+$i<=$#sdx;$j++)
          {
            my $join = join('',@sdx[$i..($i+$j)]);
            _add_target($sdx_join{$cat},$join,$id);
          }

        if($i > 0)
          {
            my $two = $sdx[$i-1]."::".$sdx[$i];
            _add_target($sdx_two{$cat},$two,$id);
          }
      }
  }

sub _add_target
  {
    # We have a diagnostic string and a result, add to the growing list
    my($hash_ref,$diag,$target) = @_;

    $hash_ref->{$diag} = []
        if(!defined $hash_ref->{$diag});
    if(ref($hash_ref->{$diag}) eq "ARRAY")
      {
        if($#{$hash_ref->{$diag}} > $max_hash_array)
          {
            # There are just too many of these to be worth 
            # looking at
            $hash_ref->{$diag} = $#{$hash_ref->{$diag}}+1;
            return;
          }
        push @{$hash_ref->{$diag}},$target;
      }
    else
      {
        # Must have so many of these as to not be worth processing

        # Keep the count
        $hash_ref->{$diag}++;
      }
  }

=head2 read_names($fh,$cat)

Read valid names from the file.  Because this prepares all the matching 
patterns it can take some time to run.

=cut

sub read_names
  {
    # Read a definitive list from a file
    my($fh,$cat) = @_;

    while(my $line = <$fh>)
      {
        # Read a seed definitive list from a file
        $line =~ s/[\n\r]+$//;

        $line =~ s/[\x00-\x1f\x7f-\xff]+//;
        next if($line =~ /^\s*#/);

        # Throw away crosslist counts (if they are present)
        $line =~ s/^\s*\{[^\}\{]+\}\s+//;

        if($line =~ /([\#\{\}\|])/)
          {
            carp("Definitive name cannot include $1 \"$line\"");
            $line =~ s/[\#\{\}\|]//g;
          }
        next if($line =~ /^\s*$/);
        add_name($cat,$line);
      }
  }

sub get
  {
    # Return the definitive name of an item
    my($cat,$start,$source,$quiet) = @_;

    if(!defined $valid_categories{$cat})
      {
        carp("Category $cat not defined\n");
        return undef;
      }
    return undef if(!defined $start);

    $source = "" if(!defined $source);

    return $id2str{$cat}->[$seen{$cat}->{lc($start)}]
                 if(defined $seen{$cat}->{lc($start)});

    my $qualifier = "";

    if(defined $qualifiers{$cat})
      {
        foreach my $qual (@{$qualifiers{$cat}})
          {
            if($start =~ s/($qual)$//i)
              {
                $qualifier = $1;
                if($seen{$cat}->{lc($start)})
                  {
                    # With the qualifier removed we have seen this
                    return $id2str{$cat}->[$seen{$cat}->{lc($start)}].$qualifier;
                  }
                last;
              }
          }
      }

    my $final_pick;

    # Find the most similar valid name
    # split the soundex into words
    my $sdx_str = MusicRoom::Text::SoundexNG::soundex($start);

    # First of all does the complete Soundex string match with 
    # any of our know values?
    if(defined $sdx_solo{$cat}->{$sdx_str} &&
               ref($sdx_solo{$cat}->{$sdx_str}) eq "ARRAY")
      {
        # In this case the soundex string from the target 
        # matches a complete soundex string in the valid set
        # Let's look at the associated values
        if($#{$sdx_solo{$cat}->{$sdx_str}} == 0)
          {
            # There is just one matching string, go with that
            $final_pick = $sdx_solo{$cat}->{$sdx_str}->[0];
            goto picked_one;
          }

        # If the sdx is exactly the same as a selection of valid strings
        # do the distance to all of them and pick the closest
        my $best_id;
        my $best_closeness;
        foreach my $this_id (@{$sdx_solo{$cat}->{$sdx_str}})
          {
            my $this_closeness = _closeness($start,$id2str{$cat}->[$this_id]);
            if(!defined $best_closeness || 
                             $this_closeness < $best_closeness)
              {
                $best_closeness = $this_closeness;
                $best_id = $this_id;
              }
          }

        # If we found a best string pick that
        if(defined $best_id)
          {
            $final_pick = $best_id;
            goto picked_one;
          }

        # The only way to get here is if the sdx_str has an empty
        # array of possible values.  In which case there is no benefit
        # to scoring it anyway.
      }

    # We have no matches for the exact soundex, we have to find a 
    # "close" valid string.  We can't do that by checking the closeness 
    # of all the valid strings (that would take too long).  So we use 
    # the soundex string to select a list of candidates
    # the way we do this is by using different combinations of the sdx
    # words to find a set
    # of candidates then using the nearest

    # Here is a hash to keep track of the strings we have encountered so 
    # far
    my %candiates;

    # Now lets look at the individual Soundex words
    my @sdx = split(/[\s_]+/,$sdx_str);

    for(my $i=0;$i<=$#sdx;$i++)
      {
        # We score for:
        #
        #     Having a single sdx word in common
        #     Having a pair of words in the same order
        #     Having a word that matches a pair concatenated
        #     Having a concatenated pair that matches a word
        #     Having a single sdx word that is "nearby" on of ours
        #
        # Each of these gives a different number of points ($score_one, 
        # $score_join etc).  We keep a list with the tally of points in 
        # the %candidates hash

        # Score for the single sdx elements
        my $one = $sdx[$i];
        _add_points($score_one,$one,$sdx_one{$cat}->{$one},\%candiates);

        # Score for joined sdx elements
        _add_points($score_join,$one,$sdx_join{$cat}->{$one},\%candiates);

        # Score for groups of elements joined in source
        for(my $j=1;($i+$j)<=$#sdx;$j++)
          {
            my $joined = join('',@sdx[$i..($i+$j)]);
            _add_points($score_nioj,$joined,$sdx_one{$cat}->{$joined},\%candiates);
          }

        # Look at pairs of sdx elements
        next if($i < 1);
        my $two = $sdx[$i-1]."::".$sdx[$i];
        _add_points($score_two,$two,$sdx_two{$cat}->{$two},\%candiates);

        # Look for nearby soundex strings
        if(defined $sdx_nearby{$one})
          {
            foreach my $nearby_sdx (@{$sdx_nearby{$one}})
              {
                _add_points($score_nearby,$nearby_sdx,
                              $sdx_one{$cat}->{$nearby_sdx},\%candiates);
              }
          }
      }

    # Now we want the highest scoring candidates

    # Sort the candidates by increasing distance from the string
    # (as measured by the soundex comparison)
    my $fun = sub{$candiates{$b} <=> $candiates{$a}};
    my @best_pick = sort $fun (keys %candiates);

    if($verbose)
      {
        # Tell the caller which candidates we end up with
        print STDERR "Similar::get(\"$cat\",\"$start\",\"$source\");\n";
        my $out_count = 0;
        foreach my $val (@best_pick)
          {
            $out_count++;
            if($out_count > 30)
              {
                printf STDERR "  ...\n";
                last;
              }
            printf STDERR "  %05d \|%s\|\n",$val,$id2str{$cat}->[$val];
          }
      }

    my $do_map = "";

    if($#best_pick < 0)
      {
        # No candidates at all!

        if($verbose)
          {
            print STDERR "Similar::get(\"$cat\",\"$start\",\"$source\");\n";
            print STDERR "  Nothing from Sdx\n";
          }

        # This would be the obvious thing to do, and it both takes a long
        # time and doesn't often work
#        foreach my $cand (keys %{$seen{$cat}})
#          {
#            my $score = _closeness($start,$cand);
#            if(!defined $best_score || $best_score > $score)
#              {
#                $best_score = $score;
#                $best_str = $cand;
#                if($verbose)
#                  {
#                    printf STDERR "  %05d \|$cand\|\n",$score;
#                  }
#              }
#          }
#        $best_pick[0] = $best_str;
#        $do_map = 1;
      }
    elsif($#best_pick == 0)
      {
        # Only one candiate, we'll go for that one
        $do_map = 1;
      }
#    elsif(($candiates{$best_pick[0]} / ($candiates{$best_pick[1]}+1)) > $score_ratio)
#      {
#        # We pass the first/second ratio
#        $do_map = 1;
#      }
    else
      {
        # The top few candidates are too close to call, do a more 
        # detailed examination of just the strings that are closest
#        my @could_be;
#
#        my $target_score = int($candiates{$best_pick[0]} / $score_ratio);
#        for(my $i=0;$i<=$#best_pick;$i++)
#          {
#            last if($candiates{$best_pick[$i]} < $target_score);
#            push @could_be,$best_pick[$i];
#          }
#        $best_pick[0] = _closest($cat,$start,@could_be);
#        $do_map = 1;
        $best_pick[0] = _closest($cat,$start,@best_pick);
        $do_map = 1;
      }

    if($do_map)
      {
        $final_pick = $best_pick[0];
picked_one:
        my $final_str = $id2str{$cat}->[$final_pick];
        error("Matching $source $cat \"$start\" to \"$final_str\"") if(!$quiet);
        $seen{$cat}->{lc($start)} = $final_pick;
        return $final_str.$qualifier;
      }

    error("Cannot find match for $source $cat \"$start\"") if(!$quiet);
    return undef;
  }

{
    my @length_factors;

sub _add_points
  {
    # Distribute some points to candidates that have a matching sdx element
    my($score,$str,$candidates_array,$ret_hr) = @_;

    return if(!defined $candidates_array ||
              ref($candidates_array) ne "ARRAY");

    if(!@length_factors)
      {
        @length_factors = (3,3,4,5,8,12,17,22,27,30);
      }

    my $length_factor;
    if(length($str) > $#length_factors)
      {
        $length_factor = $length_factors[$#length_factors];
      }
    else
      {
        $length_factor = $length_factors[length($str)];
      }

    my $score_each = int(($score*$length_factor)/
                             ($#{$candidates_array} + 1));
    foreach my $cand (@{$candidates_array})
      {
        ${$ret_hr}{$cand} = 0
                     if(!defined ${$ret_hr}{$cand});
        ${$ret_hr}{$cand} += $score_each;
      }
  }
}

sub _closest
  {
    # We have an ordered list of "closeish" strings, return the best 
    # match
    my($cat,$match,@against) = @_;

    my($best_score,$best_id);

    # Dont look at the soundex
    if($verbose)
      {
        print STDERR "_closest(\"$match\")\n";
      }
#    foreach my $test_id (@against)
#      {
#        my $test_str = $id2str{$cat}->[$test_id];
#        my $this_dist = 4*Text::LevenshteinXS::distance($match,$test_str)+
#                          Text::LevenshteinXS::distance(lc($match),lc($test_str));
#        if(!defined $best_score || $this_dist < $best_score)
#          {
#            $best_score = $this_dist;
#            $best_id = $test_id;
#            if($verbose)
#              {
#                printf STDERR "    %04d %6d \"$test_str\"\n",$best_score,$best_id;
#              }
#          }
#      }
#    return $best_id;

    my $sdx_str = MusicRoom::Text::SoundexNG::soundex($match);

    foreach my $try_id (@against)
      {
        # Combine the closeness of the full text and the soundex text
        my $try_str = $id2str{$cat}->[$try_id];
        my $sdx_score = _closeness($sdx_str,
                           MusicRoom::Text::SoundexNG::soundex($try_str));
        my $full_score = _closeness($match,$try_str);

        my $score;

        if(!defined $sdx_ratio || $sdx_ratio > 100)
          {
            $score = $sdx_score;
          }
        elsif($sdx_ratio == 0)
          {
            $score = $full_score;
          }
        elsif($sdx_ratio > 1)
          {
            $score = $full_score + int($sdx_score * $sdx_ratio);
          }
        else
          {
            $score = int($full_score/$sdx_ratio) + $sdx_score;
          }

        # Need a measure here that reflects how close the two strings are
        if(!defined $best_score || $best_score > $score)
          {
            $best_score = $score;
            $best_id = $try_id;
            printf STDERR "  [%4d,%4d] => %4d  \|%s\|\n",$sdx_score,$full_score,
                                $score,$try_str if($verbose);
          }
      }

    carp("No candidates passed to _closest\n") if(!defined $best_id);
    return $best_id;
  }

sub _closeness
  {
    # Measure how far apart two strings are
    my($str1,$str2) = @_;

    # Really want to know how many insertions and deletions to get between the 
    # two strings
#    my $dist = Text::WagnerFischer::distance([0,1,1],$str1,$str2);
    my $dist = Text::LevenshteinXS::distance($str1,$str2);
    return 0 if($dist == 0);

    return 1+int(($dist * 200)/(length($str1)+length($str2)));
  }

sub _lexically
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
        return _lexically($a_2,$b_2)
                       if($a_1 == $b_1);
        return $a_1 <=> $b_1;
      }
    if($a_t == 1 && $b_t == 1)
      {
        my $r = lc($a_1) cmp lc($b_1);
        return _lexically($a_2,$b_2)
                       if($r == 0);
        return $r;
      }
    return -1
        if($a_t == 0);
    return 1;
  }

sub verbose
  {
    $verbose = $_[0] if(defined $_[0]);
    return $verbose;
  }

sub cache_file_name
  {
    my($cat) = @_;

    my $musicroom_dir = MusicRoom::get_conf("dir");

    mkdir(${musicroom_dir}."nearest_cache")
                if(!-d ${musicroom_dir}."nearest_cache");

    return ${musicroom_dir}."nearest_cache/${cat}.cache";
  }

sub _compute_nearby
  {
    my($force) = @_;

    # Regenerating these tables takes a long time, we only need
    # to do that when we really need them
    return if($dont_regenerate_nearby_tables);

    foreach my $cat (keys %sdx_one)
      {
        $sdx_nearby{$cat} = {}
                    if(defined $force && $force);
        $sdx_nearby{$cat} = {}
                if(!defined $sdx_nearby{$cat});
        next if(%{$sdx_nearby{$cat}});

        # This is a one-off process that fills the nearby single sdx
        # with a list of close ones

        # The "proper" distance function takes too long to compute
        # so this routine just sorts all the strings and compares
        # the sorted values.  For example if we have 
        #    "dstd" and 
        my @sdx = keys %{$sdx_one{$cat}};
#        my @sorted;
#
#        for(my $i=0;$i<=$#sdx;$i++)
#          {
#            $sorted[$i] = join('',sort split(//,$sdx[$i]));
#          }

        for(my $i=0;$i<=$#sdx;$i++)
          {
            if($verbose)
              {
                print STDERR "Compute distances from $cat $sdx[$i]\n";
              }
            for(my $j=$i+1;$j<=$#sdx;$j++)
              {
#                my $dist = _sorted_dist($sorted[$i],$sorted[$j],3);
#    
#                next if($dist >= 3);
#                if($dist < 3)
#                my $dist = Text::WagnerFischer::distance([0,1,1],$sdx[$i],$sdx[$j]);
                my $dist = Text::LevenshteinXS::distance($sdx[$i],$sdx[$j]);
                if($dist < 3)
                  {
                    _add_target($sdx_nearby{$cat},$sdx[$i],$sdx[$j]);
                    _add_target($sdx_nearby{$cat},$sdx[$j],$sdx[$i]);
                  }
              }
          }
      }
  }

sub _sorted_dist
  {
    # Distance between sorted strings
    my($str1,$str2,$max_dist) = @_;

    my($dist,$idx1,$idx2);
    $dist = $idx1 = $idx2 = 0;
    my $len1 = length($str1);
    my $len2 = length($str2);
    my @str1 = unpack("c12",$str1);
    my @str2 = unpack("c12",$str2);
    while($dist < $max_dist && ($idx1 < $len1 || $idx2 < $len2))
      {
        if($idx1 >= $len1)
          {
            $idx2++;
            $dist++;
            next;
          }
        if($idx2 >= $len2)
          {
            $idx1++;
            $dist++;
            next;
          }
        if($str1[$idx1] == $str2[$idx2])
          {
            # This is a match
            $idx1++; $idx2++;
          }
        elsif($str1[$idx1] < $str2[$idx2])
          {
            $idx1++;
            $dist++;            
          }
        else
          {
            $idx2++;
            $dist++;            
          }
      }
    return $dist;
  }

sub save_cache
  {
    # Save the current settings in a cache file that will speedup 
    # starting the app next time
    my($cat) = @_;

    _compute_nearby();

    # What would be a good name for the cache file?
    my $cache_file = cache_file_name($cat);

    my $fh = IO::File->new(">$cache_file");
    if(!defined $fh)
      {
        carp("Failed to create cache file for $cat");
        return;
      }
    local $Data::Dumper::Indent = 1;         # mild pretty print

    print $fh "20070221::$cat\n";
    print $fh Data::Dumper->Dump([$id2str{$cat},$seen{$cat},$rename{$cat},
                                  $sdx_solo{$cat},
                                  $sdx_one{$cat},$sdx_two{$cat},$sdx_join{$cat},
                                  $sdx_nearby{$cat}],
                           ['id2str','seen','rename',
                            'sdx_solo','sdx_one','sdx_two',
                            'sdx_join','sdx_nearby',]);
    $fh->close();
  }

sub read_cache
  {
    # Read the settings from a cache file, rather than from the 
    my($cat,$file_name) = @_;

    # We can read the cache if the file has not been changed
    # more recently than the cache file
    my $cache_file = cache_file_name($cat);

    return ""
           if(!defined $cache_file || 
              !-r $cache_file || 
              (stat($cache_file))[9] < (stat($file_name))[9]);

    # Read the cache file
    my($id2str,$seen,$rename,$sdx_one,$sdx_solo,$sdx_two,$sdx_join,$sdx_nearby);

    my $fh = IO::File->new($cache_file);
    my $id = <$fh>;
    chomp($id);
    if($id ne "20070221::$cat")
      {
        carp("Cache file $cache_file appears incompatible with this version, ignoring");
        return "";
      }
    eval(join("",<$fh>));
    $fh->close();

    $id2str{$cat}   = $id2str;
    $seen{$cat}     = $seen;
    $rename{$cat}   = $rename;
    $sdx_solo{$cat} = $sdx_solo;
    $sdx_one{$cat}  = $sdx_one;
    $sdx_two{$cat}  = $sdx_two;
    $sdx_join{$cat} = $sdx_join;
    $sdx_nearby{$cat} = $sdx_nearby;
    _compute_nearby();

    return 1;
  }

1;

