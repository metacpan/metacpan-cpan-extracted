# Copyright 2000-2002 Dave Olszewski.  All rights reserved.
# Perlish way to generate snoof (language which appears to be real but is 
#  in fact, not)
# Distributed under the terms of GPL Version 2

package Silly::Werder;

$Silly::Werder::VERSION='0.90';

use strict;
use Exporter;
use Storable;
use File::Spec::Functions;

use constant SENTENCE     => ".";
use constant QUESTION     => "?";
use constant EXCLAMATION  => "!";

use vars qw($VERSION $PACKAGE
            @ISA
            @EXPORT_OK
           );

@ISA = 'Exporter';

my @werder_functions = qw(line sentence question exclaimation exclamation
                          set_werds_num set_syllables_num set_language
                          set_hard_syllable_max end_with_newline get_werd
                          set_unlinked dump_syllables dump_grammar build_grammar
                          load_grammar_file load_syllable_file
                          set_cons_weight);

@EXPORT_OK = (@werder_functions);

my $self;

sub new {
  my $self = {};
  bless $self;

  # Initialize the internal variables
  $self->_init($self);

  return $self;
}

sub DESTROY { }

##########################################################################
#  Sets the min and max number of werds that will go into the sentence
##########################################################################
sub set_werds_num($$) {

  my $obj;
  if(scalar(@_) == 3) {
    $obj = shift;
  }

  my ($min, $max) = @_;
  my $target;
  if($min > $max) { return -1; }

  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  $target->{"min_werds"} = $min;
  $target->{"max_werds"} = $max;

  return 0;

}


##########################################################################
#  Sets the min and max number of syllables that can go into a werd
##########################################################################
sub set_syllables_num($$) {

  my $obj;
  if(scalar(@_) == 3) {
    $obj = shift;
  }

  my ($min, $max) = @_;
  my $target;
  if($min > $max) { return -1; }

  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  $target->{"min_syllables"} = $min;
  $target->{"max_syllables"} = $max;

  return 0;

}


##########################################################################
#  Sets a hard max syllables per werd
##########################################################################
sub set_hard_syllable_max($) {

  my $obj;
  if(scalar(@_) == 2) {
    $obj = shift;
  }

  my $target;
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  my $max = shift;
  if($max < 0) { return -1; }
  if($max < $target->{"syllables_min"}) { return -1; }

  $target->{"hard_syllable_max"} = $max;

  return 0;
}


##########################################################################
#  Sets whether you want to end sentences in a newline
##########################################################################
sub end_with_newline($) {

  my $obj;
  if(scalar(@_) == 2) {
    $obj = shift;
  } 
  
  my $target;
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }
  
  my $yesno = shift;
  
  $target->{"end_with_newline"} = $yesno;
  
  return 0;
} 


##########################################################################
#  Sets whether you want fully random mode or not (not recommended)
##########################################################################
sub set_unlinked($) {
  my $obj;
  if(scalar(@_) == 2) {
    $obj = shift;
  } 

  my $target;
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  my $yesno = shift;
 
  $target->{"unlinked"} = $yesno;
  
  return 0;
}

##########################################################################
#  Set the percentage of the time a werd will start with a consonant 
#  This function is OBSOLETE and is only kept for compatibility
##########################################################################
sub set_cons_weight($) {
  return 0;
}

##########################################################################
#  Create a random type of sentence
##########################################################################
sub line {
  my $obj;
  if(scalar(@_) == 1) {
    $obj = shift;
  }

  my ($line, $target);
  my $which_kind = int(rand() * 3);

  
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  if($which_kind == 0) { $line = _make_line($target, SENTENCE); }
  if($which_kind == 1) { $line = _make_line($target, QUESTION); }
  if($which_kind == 2) { $line = _make_line($target, EXCLAMATION); }

  return $line;
}

##########################################################################
#  Create a sentence with a period
##########################################################################
sub sentence {
  my $obj;
  if(scalar(@_) == 1) {
    $obj = shift;
  }

  my $target;

  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  my $line = _make_line($target, SENTENCE);
  return $line;
}

##########################################################################
#  Create a question
##########################################################################
sub question {
  my $obj;
  if(scalar(@_) == 1) {
    $obj = shift;
  }

  my $target;

  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  my $line = _make_line($target, QUESTION);
  return $line;
}

##########################################################################
#  Create an exclamation
##########################################################################
sub exclamation {
  my $obj;
  if(scalar(@_) == 1) {
    $obj = shift;
  }

  my $target;

  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  my $line = _make_line($target, EXCLAMATION);
  return $line;
}

##########################################################################
#  Make and return a single werd
##########################################################################
sub get_werd {
  my $obj = shift;

  my $target;
    
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }
  
  my $werd = _make_werd($target);
  return $werd;
}

# For backwards compatibility with spelling error from previous release
# Do it twice to quelch "only used once" warnings
*exclaimation = *exclamation;
*exclaimation = *exclamation;

##########################################################################
#  Set the language/grammar to use
##########################################################################
sub set_language($) {
  my ($obj, $language, $variant) = @_;
  my $target;

  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  my $module = "Silly::Werder::" . $language;
  eval "require $module";
  import $module (qw/LoadGrammar/);

  my ($grammar, $index) = LoadGrammar($variant);
  $obj->{"grammar"} = $grammar;
  $obj->{"index"} = $index;
}



##########################################################################
#  Initialize class/object data
##########################################################################
sub _init {
  my $obj = shift;

  if(ref $obj) {
    $obj->{"min_werds"} = 5;
    $obj->{"max_werds"} = 9;

    $obj->{"min_syllables"} = 3;
    $obj->{"max_syllables"} = 7;
  }
  else {
    $self->{"min_werds"} = 5;
    $self->{"max_werds"} = 9;

    $self->{"min_syllables"} = 3;
    $self->{"max_syllables"} = 7;
  }
}

# Call the init function at the time we load the module to initialize the vars
# for class methods
_init();

##########################################################################
#  Called from _make_werd to make sure a grammar is loaded
##########################################################################
sub _check_grammar {
  my $obj = shift;

  if(!$obj->{"grammar"} or !$obj->{"index"}) {
    bless $obj; # a hack to get set_language to work
    $obj->set_language("English");
  }
}


##########################################################################
#  Internal method to make a single werd
##########################################################################
sub _make_werd {
  my ($obj, $target, $i);

  if(scalar(@_) == 1) {
    $obj = shift;
  }
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  _check_grammar($target);

  my $syl = "_BEGIN_";
  my $werd = "";
  my $which;
  my $sylcount = 0;

  # Full random mode
  if($target->{"unlinked"}) {
    my $syl_num = int(rand() * ($target->{"max_syllables"} 
       - $target->{"min_syllables"} + 1)) + $target->{"min_syllables"};

    for(my $i = 0; $i < $syl_num; $i++) {

      do {
        $which = int(rand() * scalar(@{$target->{"grammar"}}));
      } while(($target->{"grammar"}[$which][0] eq "_BEGIN_") or 
             ($target->{"grammar"}[$which][0] eq "_END_"));

      $werd .= $target->{"grammar"}[$which][0];
    }
    return($werd);
  }
  # Regular linked mode
  else {
    while($syl ne "_END_") {
  
      # End the word on time if we have a hard max set
      if(($target->{"hard_syllable_max"}) and
         ($sylcount >= $target->{"hard_syllable_max"})) {
        last;
      }
  
      $which = -1;
      if($syl ne "_BEGIN_") { $werd .= $syl; }
      my $offset = $target->{index}{$syl};
      my $count = scalar(@{$target->{"grammar"}[$offset][1]})
        if $target->{"grammar"}[$offset][1];
      if($sylcount >= ($target->{max_syllables} - 1)) {
        # Try to choose an ending
        $which = -1;
        for($i = 0; $i < $count; $i++) {
          if($target->{"grammar"}[$offset][1][$i][0] eq "_END_") {
            $which = $i;
            last;
          }
        }
      }
      if($which < 0) {
        my ($freq_total, $freq);
  
        foreach $freq (@{$target->{"grammar"}[$offset][2]}) {
          $freq_total+= $freq;
        }

        do {
          my ($freq_sum, $i, $which_freq);
  
          $which_freq = int(rand() * $freq_total + 1);
          for($i = 0; $i < scalar(@{$target->{"grammar"}[$offset][2]}); $i++) {
            $freq_sum += $target->{"grammar"}[$offset][2][$i];
            if($freq_sum >= $which_freq) {
              $which = $i;
              last;
            }
          }
        } while(($target->{"grammar"}[$offset][1][$which][0] eq "_END_") and
                ($count > 1) and ($sylcount < $target->{"min_syllables"}));
      }
      $syl = $target->{"grammar"}[$offset][1][$which][0];
      $sylcount++;
    }
  }

  return($werd);
}


##########################################################################
#  Internal method to make a line of werds
##########################################################################
sub _make_line {
  my ($obj, $target);

  if(scalar(@_) == 2) {
    $obj = shift;
  }
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  my $ending = shift;
  my ($line, $num_werds, $werd_counter);

  $num_werds = int(rand() * ($target->{"max_werds"}
      - $target->{"min_werds"} + 1) + $target->{"min_werds"});

  for($werd_counter = 0; $werd_counter < $num_werds; $werd_counter++) {
    $line .= " " . _make_werd($target);
  }

  $line =~ s/^.(.)/uc($1)/e;
  $line .= $ending;

  if($target->{"end_with_newline"}) {
    $line .= "\n";
  }

  return $line;
}


###########################################################
###                 GRAMMAR FUNCTIONS                   ###
###########################################################

##########################################################################
#  Load the syllable file
##########################################################################
sub _load_syllables {
  my $obj = shift;
  my $indexed_syllables;

  my $target;
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  (my $dir = $INC{'Silly/Werder.pm'}) =~ s/\.pm//;
  $dir = catdir($dir, 'data');
  my $syllable_file = catfile($dir, 'syllables');

  # Load the syllable list
  open SYLS, $syllable_file or return(-1);
  chomp(my @syllables = <SYLS>);
  close SYLS;

  # Sort the list, but sorting longer words higher
  @syllables=sort { my $min=(length($a) < length($b)) ? length($a) : length($b);
            ( substr(lc($a),0,$min) cmp substr(lc($b),0,$min) ||
              length($b) <=> length($a) )
            } @syllables;

  # Remove duplicates (important for recursive parse)
  for(my $i = 1; $i < scalar(@syllables); $i++) {
    if(lc($syllables[$i]) eq lc($syllables[$i - 1])) {
      @syllables = splice(@syllables, $i, 1);
      $i--;
    }
  }

  my $syl;
  foreach $syl (@syllables) {
    $syl =~ /^((.).?)/;
    my $first = lc($2);
    my $firsttwo = lc($1);
    if($first eq $firsttwo) { $firsttwo = "_"; }
    push @{$indexed_syllables->{$first}{$firsttwo}}, $syl;
  }

  $target->{"syllables"} = $indexed_syllables;

  return(0);
}

##########################################################################
#  Dump the syllables to a user named file
##########################################################################
sub dump_syllables($) {
  my $obj = shift;
  my (%syls, $syl, @syl_sort);

  my $target;
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  if(!$target->{"syllables"}) {
    if(_load_syllables($target) < 0) { return -1; }
  }

  my $syl_out_file = shift;
  open SYL_OUT, ">$syl_out_file" or return -1;

  # Un-hash the syllables into one big hash to make sure there's no dups
  foreach my $first (keys %{$target->{"syllables"}}) {
    foreach $syl (@{$target->{"syllables"}{$first}{_}}) {
      $syls{$syl} = 1;
    }
    foreach my $firsttwo (keys %{$target->{"syllables"}{$first}}) {
      foreach $syl (@{$target->{"syllables"}{$first}{$firsttwo}}) {
        $syls{$syl} = 1;
      }
    }
  }

  # Sort the list, but sorting longer words higher
  @syl_sort=sort { my $min=(length($a) < length($b)) ? length($a) : length($b);
            ( substr($a,0,$min) cmp substr($b,0,$min) ||
              length($b) <=> length($a) )
            } keys(%syls);


  foreach $syl(@syl_sort) {
    print SYL_OUT "$syl\n";
  }

  close SYL_OUT;

  return 0;
}

##########################################################################
#  Parse a word and pass back the syllable pairs and number of word variants
##########################################################################
sub _parse_werd($$$;$$$);
# Needs a prototype because it's recursive and Perl cries otherwise
sub _parse_werd($$$;$$$) {
  my ($target, $werd, $werd_account, $werd_parts, $variations, $start_at) = @_;
  my ($syl, $ready, $next_syl);

  # Make sure ref contains something;
  ${$variations} += 0;

  if($werd eq "") {
    my $first = $werd_parts->[0];
    my $last = $werd_parts->[$#{$werd_parts}];
    my $i;

    $werd_account->{"_BEGIN_"}{$first} = 1;
    $werd_account->{$last}{"_END_"} = 1;

    for($i = 1; $i <= $#{$werd_parts}; $i++) {
      $werd_account->{$werd_parts->[$i-1]}{$werd_parts->[$i]} = 1;
    }

    ${$variations}++;

    undef $werd_parts;
  }

  $werd =~ /^((.).?)/;
  my $first = lc($2);
  my $firsttwo = lc($1);
  # gotta remember to check for syls that are just 1 in length
  foreach $syl (@{$target->{"syllables"}{$first}{_}}, 
                @{$target->{"syllables"}{$first}{$firsttwo}}) {
    $next_syl = 0;
    if($start_at && !$ready) { $next_syl = 1; }
    if(($syl eq $start_at) || !$start_at) { $ready = 1; }
    next if $next_syl;


    if($werd =~ /^$syl(.*)$/si) {
      push @{$werd_parts}, $syl;
      _parse_werd($target, $1, $werd_account, $werd_parts, $variations);
      return(${$variations});
    }
  }


  if($werd_parts and scalar(@{$werd_parts})) {
    my $oldsyl = pop @{$werd_parts};
    _parse_werd($target, $oldsyl . $werd, $werd_account,
                $werd_parts, $variations, $oldsyl);
    return(${$variations});
  }
  else {
    return(${$variations});
  }
}

##########################################################################
#  Build a grammar from a passed in block of text
##########################################################################
sub build_grammar($;$$$) {

  require POSIX;
  import POSIX (qw/locale_h/);
  require locale;

  my $charset = "A-Za-z\xa0-\xbf\xc0-\xd6\xda-\xdd\xdf-\xf6\xf9-\xfd\xff'\\-";
  my (%account, $grammar, $index, $couldnts);

  my $obj = shift;

  my $target;
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }

  my ($text, $appears_threshold, $follower_threshold, $locale) = @_;

  if($locale) {
    my $ret = setlocale("LC_CTYPE", $locale);
    if(!defined($ret)) {
      print STDERR "Could not load locale $locale: $!\n";
    }
  }

  if(_load_syllables($target) < 0) { return; }

  while($text =~ /[^$charset]*([$charset]+)[^$charset]*/sig) {
    my $werd = $1;
    $werd =~ s/^['\-]*//;
    $werd =~ s/['\-]*$//;
    if($werd eq "") { next; }

    my $werd_account = {};
    my $variations = _parse_werd($target, $werd, $werd_account);
    if($variations == 0) {
      push @{$couldnts}, $werd;
    }
    else {
      my $syllable;
      foreach $syllable (keys %{$werd_account}) {
        my $follower;
        foreach $follower (keys %{$werd_account->{$syllable}}) {
          $account{$syllable}{$follower}++;
        }
      }
    }
  }

  $grammar->[0][0] = "_BEGIN_";
  $index->{"_BEGIN_"} = 0;

  # Go through list and remove links that appear less than appears_threshold
  my $syllable;
  foreach $syllable (keys %account) {
    my $follower;
    foreach $follower (keys %{$account{$syllable}}) {
      if($account{$syllable}{$follower} < $appears_threshold) {
        delete $account{$syllable}{$follower};
      }
    }
  }

  my $syls_removed = 1;
  while($syls_removed) {
    $syls_removed = 0;

    foreach $syllable (keys %account) {

      my $explicit_keep = 0;
      my $linkcount = scalar(keys %{$account{$syllable}});

      # check for _END_ first, so good endings don't get removed
      my $follower;
      foreach $follower (keys %{$account{$syllable}}) {
        if($follower eq "_END_") { $explicit_keep = 1; }
      }
      if($explicit_keep) { next; }

      if($linkcount < $follower_threshold) {

        my $prior;
        # sub loop to remove links to this node
        foreach $prior (keys %account) {
          if($account{$prior}{$syllable}) {
            delete $account{$prior}{$syllable};
          }
        }

        delete $account{$syllable};
        $syls_removed = 1;
      }
    }
  }

  my $syllable_count;
  foreach $syllable (keys %account) {

    my $offset = $index->{$syllable};
    if(!defined($index->{$syllable})) {
      $syllable_count++;
      $grammar->[$syllable_count][0] = $syllable;
      $offset = $syllable_count;
      $index->{$syllable} = $offset;
    }

    my $follower;
    foreach $follower (keys %{$account{$syllable}}) {

      my $follower_offset = $index->{$follower};
      if(!$follower_offset) {
        $syllable_count++;
        $grammar->[$syllable_count][0] = $follower;
        $follower_offset = $syllable_count;
        $index->{$follower} = $follower_offset;
      }

      push @{$grammar->[$offset][1]}, \@{$grammar->[$follower_offset]};
      push @{$grammar->[$offset][2]}, $account{$syllable}{$follower};
    }
  }


  $target->{"grammar"} = $grammar;
  $target->{"index"} = $index;

  return($couldnts);
}


##########################################################################
#  Dump the current grammar to a user named file
##########################################################################
sub dump_grammar($) {
  my $obj = shift;
    
  my $target;
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }
    
  if(!$target->{"grammar"}) {
    bless $target; # a hack to get set_language to work
    $target->set_language("English");
  }

  my $grammar_out_file = shift;
  
  if(!Storable::nstore($target->{"grammar"}, $grammar_out_file)) {
    return -1;
  }

  return 0;
}

##########################################################################
#  Load in a user-specified grammar from an external file
##########################################################################
sub load_grammar_file($) {
  my $obj = shift;
  my $index_ref;

  my $target;
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }
    
  my $grammar_in_file = shift;
  
  my $grammar_ref = retrieve($grammar_in_file);
  if(!defined($grammar_ref)) { return -1; }

  my $count = scalar(@{$grammar_ref});

  for(my $i = 0; $i < $count; $i++) {
    $index_ref->{$grammar_ref->[$i][0]} = $i;
  }

  $target->{"grammar"} = $grammar_ref;
  $target->{"index"} = $index_ref;

  return 0;
}

##########################################################################
#  Load in a user-specified grammar from an external file
##########################################################################
sub load_syllable_file($) {
  my $obj = shift;
  my $indexed_syllables;
  
  my $target;  
  if(ref $obj) { $target = $obj; }
  else { $target = $self; }
    
  my $syllable_file = shift;

  # Load the syllable list
  open SYLS, $syllable_file or return -1;
  chomp(my @syllables = <SYLS>);
  close SYLS;

  # Sort the list, but sorting longer words higher
  @syllables=sort { my $min=(length($a) < length($b)) ? length($a) : length($b);
            ( substr(lc($a),0,$min) cmp substr(lc($b),0,$min) ||
              length($b) <=> length($a) )
            } @syllables;

  # Remove duplicates (important for recursive parse)
  for(my $i = 1; $i < scalar(@syllables); $i++) {
    if(lc($syllables[$i]) eq lc($syllables[$i - 1])) {
      @syllables = splice(@syllables, $i, 1);
      $i--;
    }
  }

  my $syl;
  foreach $syl (@syllables) {
    $syl =~ /^((.).?)/;
    my $first = lc($2);
    my $firsttwo = lc($1);
    if($first eq $firsttwo) { $firsttwo = "_"; }
    push @{$indexed_syllables->{$first}{$firsttwo}}, $syl;
  }

  $target->{"syllables"} = $indexed_syllables;

  return 0;
}

1;

__END__

=head1 NAME

Werder - Meaningless gibberish generator

=head1 SYNOPSIS

  use Silly::Werder;

  my $werds = new Silly::Werder;

  # Set the min and max number of werds per line
  $werds->set_werds_num(5, 9);      

  # Set the min and max # of syllables per werd
  $werds->set_syllables_num(3, 7);

  # End the sentences in a newline
  $werds->end_with_newline(1);

  # Set the language to mimic
  $werds->set_language("English", "small");

  # Return a random sentence, question, or exclamation
  $line = $werds->line;

  $sentence    = $werds->sentence;
  $question    = $werds->question;
  $exclamation = $werds->exclamation;

  # Get a single werd
  $werd = $werds->get_werd;

  # Generate a long random sentence calling as a class method
  Silly::Werder->set_werds_num(10,20);
  print Silly::Werder->line;

  # All of the methods can be used as either class methods
  # or object methods.

=head1 DESCRIPTION

This module is used to create pronounceable yet completely meaningless 
language.  It is good for sending to a text-to-speech program (ala festival), 
generating passwords, annoying people on irc, and all kinds of fun things.

This new release is a full rewrite of the engine.  It is based on grammar files
derived from real text of real languages.  Several grammars are provided for
you to use, and you can also create your own.

=head1 FUNCTIONS

=over 8

=item set_werds_num(min, max)

Sets the minimum and maximum werds to be generated.  Both arguments are
required.  min must be lower than max.  Returns 0 on success, -1 on error.

=item set_syllables_num(min, max)

Sets the minimum and maximum syllables per werd.  The max is a soft limit
unless you call B<set_hard_syllable_max> with a non-zero argument.  The reason
for this is that in mimicking real speech, not every syllable is a valid ending
to a werd.  If this is called with either min or max higher than the value set
by B<set_hard_syllable_max>, the hard max will be disabled.  Returns 0 on
success, and -1 on error.

=item set_hard_syllable_max(max)

Sets the hard max for syllables in a werd.  This will end a werd when it's 
reached this number of syllables regardless of whether it makes sense as an
ending or not.  Setting this to zero will disable it.  If you pass a non-zero
value lower than the current minimum, it will not set the hard max and return
-1.  Returns 0 on success.

=item end_with_newline(boolean)

B<Silly::Werder no longer returns sentences with a newline at the end by
default!>

If you want that behavior, call this function with a non-zero argument.
Calling with zero will disable it.

=item set_unlinked(boolean)

If you want to ignore the syllable linkage built into a grammar and just pick
random syllables, call this with a non-zero argument.  To disable, call with
0.  This feature is off by default.

=item set_language(language, [variant])

Load a different language grammar than the default (which is English).  The
languages included with Silly::Werder are

=over 4

=item English         - the default grammar

=item English, small  - a smaller and faster English

=item German          - a German derived grammar

=item German, small   - smaller German

=item French          - a French derived grammar

=item French, small   - smaller French

=item Swedish         - a Swedish derived grammar

=item Swedish, small  - smaller Swedish

=item Shakespeare     - a grammar modeled after The Bard

=back
 
=item sentence

Generate a random sentence and end in period.  

=item question

Same as sentence but with a ? at the end.

=item exclamation

Same as sentence but with a ! at the end.  In previous versions this was
misspelled as exclaimation.  That method is deprecated but still works for
compatibility.

=item line

Creates a sentence with . ? or ! randomly.

=item get_werd

Create and return a single werd.

=back

=head1 CUSTOM GRAMMAR FUNCTIONS

=over 8

=item build_grammar(text, [appear, [follow, [locale]]])

By calling this routine, you can build your own grammar to produce
Silly::Werder text.

* The first argument should be a scalar containing text to parse.  If this text
is not sufficiently long, there will not be enough of a sample to generate
decent werds so be sure to feed it enough!

The appear and follow arguments are thresholds that Silly::Werder uses to 
determine if a particular syllable pair is worthy of adding to the grammar.  
These are mainly used to reduce the size of the resulting grammar.  

* appear means that the pair must appear in that order greater than or equal to 
that number of times.

* follow means that any given syllable must have that number of unique other
syllables (the end of a word is a special "syllable", and counts as 1).

* locale is your system locale which can be used to let Perl know what is
upper and lower case for a particular locale.  In other words, if you are
parsing French, pass fr_FR, if you are parsing German, pass de_DE.  This is
not required but will improve the results of your grammar.  Also note that
your system needs to have the locales you want installed in order to use them.
See the perllocale pod for more information.

This routine will return an array reference containing any words that were
unable to be parsed.

=item dump_grammar(filename)

This routine will save the current grammar used by Silly::Werder to a file
who's path is passed as the argument.  If no grammar has been loaded, it will
load and dump English.  Returns -1 if there is an error, and 0 on success.

=item dump_syllables(filename)

This routine will save the current list of syllables that is being used by
Silly::Werder to a file who's path is passed as the argument.  Returns -1 if
there is an error, and 0 on success.

=item load_grammar_file(filename)

Loads a grammar file of the format output by dump_grammar.  Returns -1 if there
is an error, and 0 on success.

=item load_syllable_file(filename)

Loads a syllable file of the format output by dump_syllables.  Returns -1 if
there is an error, 0 on success.

=back

=head1 BUGS

* Word is misspelled (quite intentionally!) as werd throughout the source and docs.

* locales not being loaded for each grammar result in incorrect capitalization sometimes.

=head1 AUTHOR

Silly::Werder was created and implemented by Dave Olszewski, aka cxreg.  You can send 
comments, suggestions, flames, or love letters to dave.o@pobox.com

=cut
