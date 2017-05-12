# The Soundex algorithm was developed to help with the variable spelling of names
# that is encountered by those doing historical research.  The concept is that 
# a simple version of the name is produced that can index all the variations.
#
# This concept has been adopted in this module, the algorithm has been adapted 
# to suit the recognition of musical tracks, thus:
#
#     The Beatles, Beatles, Beetels
#
# all map to the string "btl".
=head1 NAME

MusicRoom::Text::SoundexNG - Extended Soundex varient tuned for music tag handling

=head1 DESCRIPTION

The Soundex algorithm was developed to help with the variable spelling of names
that is encountered by those doing historical research.  The idea is that each 
name creates a string based on what it sounds like.  In this case the concept 
has been tuned for music tags (artist names, track names and album titles).  So
if someone types is "The Beatles" or "Beetels" the algorithm returns "btl".  We 
can use this to help identify artists that are good candidates for what the 
user means.

=cut

use strict;
use warnings;

use Carp;

package MusicRoom::Text::SoundexNG;

my %cache = ();

%cache = ();
my @ignore_words = ("a","the","of","and","at","it","is");

my @word_mappings;

# Certain mappings are built into the system.  For example 
# "wanna" becomes "want to"

my $builtin_map = <<'EndBuiltinMap';
in'\b=>|ing|
\b'round=>|around|
'n'=>|&|
\b'n\b=>|&|
\bn'\b=>|&|
don't=>|do not|
i'm=>|i am|
i'll=>|i will|
i've=>|i have|
can't=>|cannot|
it's=>|it is|
you're=>|you are|
he's=>|he is|
wanna=>|want to|
\b1\b=>|one|
\b2\b=>|two|
\b3\b=>|three|
\b4\b=>|four|
\b5\b=>|five|
\b6\b=>|six|
\b7\b=>|seven|
\b8\b=>|eight|
\b9\b=>|nine|
\b10\b=>|ten|
\b11\b=>|eleven|
\b12\b=>|twelve|
\b13\b=>|thirteen|
\b14\b=>|fourteen|
\b15\b=>|fifteen|
\b16\b=>|sixteen|
\b17\b=>|seventeen|
\b18\b=>|eighteen|
\b19\b=>|ninteen|
\b20\b=>|twenty|
\b30\b=>|thirty|
\b40\b=>|forty|
\b50\b=>|fifty|
\b60\b=>|sixty|
\b70\b=>|seventy|
\b80\b=>|eighty|
\b90\b=>|ninty|
\b100\b=>|one hundred|
\ba\s+hundred\b=>|one hundred|
\b1(\w)=>|one$1|
\b2(\w)=>|two$1|
\b3(\w)=>|three$1|
\b4(\w)=>|four$1|
\b5(\w)=>|five$1|
\b6(\w)=>|six$1|
\b7(\w)=>|seven$1|
\b8(\w)=>|eight$1|
\b9(\w)=>|nine$1|
\b10(\w)=>|ten$1|
\b11(\w)=>|eleven$1|
\b12(\w)=>|twelve$1|
\b13(\w)=>|thirteen$1|
\b14(\w)=>|fourteen$1|
\b15(\w)=>|fifteen$1|
\b16(\w)=>|sixteen$1|
\b17(\w)=>|seventeen$1|
\b18(\w)=>|eighteen$1|
\b19(\w)=>|ninteen$1|
\b20(\w)=>|twenty$1|
\b30(\w)=>|thirty$1|
\b40(\w)=>|forty$1|
\b50(\w)=>|fifty$1|
\b60(\w)=>|sixty$1|
\b70(\w)=>|seventy$1|
\b80(\w)=>|eighty$1|
\b90(\w)=>|ninty$1|
\b100(\w)=>|one hundred$1|
\ba\s+hundred(\w)=>|one hundred$1|
EndBuiltinMap


foreach my $map (split(/[\n\r]+/,$builtin_map))
  {
    if($map =~ /\=\>\|/)
      {
        my($from,$to) = ($`,$');
        $to =~ s/\|.*$//s;
        add_mappings($from,$to);
      }
    else
      {
        carp("Badly defined builtin mapping $map");
      }
  }

=head2 add_mappings(@mappings)

Add a list of words to map, for example:

    MusicRoom::Text::SoundexNG::add_mappings(
                  '\bwanna\b' => "want to",
                  '\boutta\b' => "out of");

Will map the word "wanna" to "want to" before applying the rest of the algorithm.

When the escape \b appears at the start or end of the pattern it will match 
the start or end of the string as well as a word boundary.

=cut

sub add_mappings
  {
    my(@mappings) = @_;

    for(my $i=0;$i*2 < $#mappings;$i++)
      {
        my(@from,@to);
        $from[0] = $mappings[2*$i];
        $to[0] = $mappings[2*$i+1];

        if($from[0] =~ /^\\b/ && $from[0] =~ /\\b$/)
          {
            $from[1] = $from[2] = $from[3] = $from[0];

            $from[0] =~ s/^\\b/\^/; $from[0] =~ s/\\b$/\$/;
            $from[1] =~ s/^\\b/\\s\+/; $from[1] =~ s/\\b$/\$/;
            $from[2] =~ s/^\\b/\^/; $from[2] =~ s/\\b$/\\s\+/;
            $from[3] =~ s/^\\b/\\s\+/; $from[3] =~ s/\\b$/\\s\+/;

            $to[1] = " ".$to[0];
            $to[2] = $to[0]." ";
            $to[3] = " ".$to[0]." ";
          }
        elsif($from[0] =~ /^\\b/)
          {
            $from[0] =~ s/^\\b/\^/;
            $from[1] = $from[0];
            $from[1] =~ s/^\^/\\s\+/;
            $to[1] = " ".$to[0];
          }
        elsif($from[0] =~ /\\b$/)
          {
            $from[0] =~ s/\\b$/\$/;
            $from[1] = $from[0];
            $from[1] =~ s/\$$/\\s\+/;
            $to[1] = $to[0]." ";
          }
        for(my $j=0;$j<=$#from;$j++)
          {
            push @word_mappings,$from[$j],$to[$j];
          }
      }
  }

=head2 (@word)

Add words to those that are removed when processing.

=cut

sub ignore_words
  {
    push @ignore_words,@_;
  }

sub _ignore_words
  {
    my($val) = @_;

    # Remove connecting words
    foreach my $word (@ignore_words)
      {
        $val =~ s/^$word\s//i;
        $val =~ s/\s$word\s/ /ig;
        $val =~ s/\s$word$//i;
      }
    return $val;
  }

sub _word_map
  {
    my($val) = @_;

    # Replace simple constructs
    for(my $i=0;2*$i<$#word_mappings;$i++)
      {
        my $from = $word_mappings[2*$i];
        my $to = $word_mappings[2*$i + 1];
        if($to =~ /\$/)
          {
            eval("\$val =~ s/$from/$to/g;");
          }
        else
          {
            $val =~ s/$from/$to/g;
          }
      }
    return $val;
  }

# Convert similar sounding letter groups to the same 
# base letter

sub _to_sounds
  {
    my($val) = @_;

    # Get to sounds
    $val =~ s/[ck]+/k/g;
    $val =~ s/[bd]+/b/g;
    $val =~ s/([fglmnprst])\1/$1/g;

    # $val =~ s/m+/m/g;
    # $val =~ s/n+/n/g;
    # $val =~ s/p+/p/g;
    # $val =~ s/s+/s/g;
    # $val =~ s/l+/l/g;
    # $val =~ s/b+/b/g;
    # $val =~ s/f+/f/g;

    $val =~ s/s\s/ /g;
    $val =~ s/s$//g;

    $val =~ s/ie$/y/g;
    $val =~ s/ie([\s_])/y$1/g;

    # Remove vowels that follow constanants
    while($val =~ s/([bcdfghjklmnpqrstvwxyz])[aeiou]/$1/)
      {
      }
    # $val =~ s/([bcdfghjklmnpqrstvwxyz])$/$1/;
    return $val;
  }

=head2 soundex($word)

Process the string to produce a soundex version.  For example

    my $sdx = MusicRoom::Text::SoundexNG::soundex("Paradise by the Dashboard Light");

sets $sdx to "prbs_by_bshbrb_lght".

=cut

sub soundex
  {
    # Process a name to produce a distinct index that identifies 
    # similar ones
    my($start) = @_;

    return undef if(!defined $start);
    # convert to lower case
    my $val = lc($start);

    return $cache{$val} if(defined $cache{$val});

    $val = _word_map($val);

    # remove things that are not words
    $val =~ s/[\'\$\`\.]//g;
    $val =~ s/[^a-z0-9 ]+/ /g;
    $val =~ s/\s+/ /g;

    $val = _ignore_words($val);

    $val = _to_sounds($val);

    # Replace spaces with _
    $val =~ s/\s+/_/g;
    $val =~ s/^_+//;
    $val =~ s/_+$//;

    # printf "%20s => %s\n",$start,$val;

    # $cache{$start} = $val;
    $cache{lc($start)} = $val;

    return $val;
  }

1;
