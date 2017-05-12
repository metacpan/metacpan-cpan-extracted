# String::REPartition, a module used to partition data using a regular
# expression.

package String::REPartition;

require 5;
use strict;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(make_partition_re);

our $VERSION = 1.6;

my $DEBUG = 0;

# This is the main (and only) accessor function for this module.  Given a
# ratio and a reference to a list of strings, it will produce a regular
# expression that will match @{$ref} * $ratio of the words in the list,
# and (this is the important part) not the rest of them.  For example, if
# $ratio is .4, the resulting regular expression will match 40% of the
# strings in the list, and will fail to match the remaining 60%.
sub make_partition_re {
  my($ratio) = shift;
  my($arryref) = shift;

  my(%lenhash) = ();
  my(@words) = ();

  # Just checking inputs here.
  warn("Checking inputs...\n") if $DEBUG;
  unless ($ratio && _is_numeric($ratio) && ($ratio > 0) && ($ratio < 1)) {
    return _whine ("Invalid ratio given.  Must be a number between 0 and 1.");
  }
  unless ($arryref && ref($arryref) && ref($arryref) eq 'ARRAY') {
    return _whine ("Invalid reference given.  Must be a reference to a list or an array.");
  }
  @words = @{ $arryref };

  chomp @words;

  # First we build a hash recording the number of strings with each length.
  foreach (@words) {
    $lenhash{length($_)}++;
  }
  if ($DEBUG) {
    print "My first length hash looks like this:\n";
    foreach my $key (sort {$a <=> $b} (keys %lenhash)) {
      print "  $key -> $lenhash{$key}\n";
    }
  }

  # And then use the _make_list subroutine to examine that hash and determine
  # a set of lengths which constitute the closest solution, given the ratio.
  my(@soln) = _make_list(\%lenhash,$ratio);
  if ($DEBUG) {
    print "First solution is: ";
    print join('--', @soln);
    print "\n";
  }

  # The new ratio will be the last value of the returned array.  It may or
  # may not be defined.  An undef ratio implies that an exact solution has
  # been found.
  $ratio = pop(@soln);
  if ($DEBUG) {
    if (defined $ratio) {
      print "I found the ratio $ratio and want to split $soln[-1]\n";
    }
    else {
      print "No ratio found -- must have found an exact solution on the first try\n";
    }
  }
  my($split) = pop(@soln) if defined $ratio;
  my($regex) = "^(";

  # If any lengths were appropriate to go into the solution (there need not 
  # be), then we'll build the first part of the regex.
  if (scalar @soln) {
    $regex .= join('|',map {'(' . '.{' . $_ . '})'} _shrink_list(@soln));
  }
  print "Regex so far is $regex\n" if $DEBUG;
  my($splitlen) = 0;
  my(%alphahash) = ();
  my(@solns) = ();

  # Now, if ratio *is* defined, that means we have to further subdivide words
  # of one of the lengths.
  if (defined($ratio)) {

    # This is just setting a bunch of stuff up.
    print "Starting to re-split\n" if $DEBUG;
    $splitlen = $split;
    my($splitval) = $lenhash{$split};
    my($letnum) = 0;
    my($total) = 0;

    # We only want to play with the words of the appropriate length.
    @words = grep( (length($_) == $splitlen), @words );

    # And now we will continue re-subdividing the words until we've been
    # asked to split the sample too much.
    until (
      (int($splitval * $ratio) <= 1) ||
      (int($splitval * $ratio) >= ($splitval - 1)) ||
      ($letnum >= $splitlen)
    ) {
      %alphahash = ();

      # Here we build a hash similar to the lenhash before.
      foreach my $word (@words) {
        $alphahash{substr($word,$letnum,1)}++;
      }

      # And then build the solution with the new data.
      @soln = _make_list(\%alphahash,$ratio);
      $ratio = pop(@soln);
      if ($DEBUG) {
        if (defined $ratio) {
          print "I found the ratio $ratio and want to split $soln[-1]\n";
        }
        else {
              print "No ratio found -- must have found an exact solution\n";
        }
      }
      # Store the solution...
      if ($DEBUG) {
        print "Adding: " . join('--',@soln) . " to the solutions.\n";
      }
      @{$solns[$letnum]} = @soln;

      # Maybe do some stuff if we have to further subdivide...
      if (defined($ratio)) {
        $split = pop(@soln);
        @words = grep( (substr($_,$letnum,1) eq $split), @words );
        $splitval = $alphahash{$split};
        $letnum++;
      }

      # Otherwise, make the loop bomb out so we can get on with our lives.
      else {
        $ratio = -1;
      }
    }
    if ($ratio >= 0 && (scalar @solns > 0)) {
      pop(@{$solns[-1]});
    }
  }

  # Now, if we have some solutions from subdividing the remaining words, 
  # we want to incorporate that into our regex...
  my($regex_annex) = "";
  if (scalar @solns) {
    my($prefix) = "";
    my($templetter) = "";
    foreach my $num (0..$#solns) {
      $splitlen--;

      # If there are more solutions in the solution array after the one
      # we're looking at, then the last letter isn't part of the solution
      # but rather the letter that'll be split for the *next* solution.
      # Thus we have to save it and store it.
      if ($num < $#solns) {
        $templetter = pop(@{$solns[$num]});
      }
      else {
        $templetter = '';
      }
      if (scalar @{$solns[$num]} > 0) {
        $regex_annex .= "($prefix\[" . join('',@{$solns[$num]}) . ']';
        if ($splitlen > 0) {
          $regex_annex .= '.{' .  $splitlen . '}';
        }
        $regex_annex .= ')|';
      }
      $prefix .= $templetter;
    }
    chop $regex_annex;
  }
  if (length($regex) > 2 && length($regex_annex)) {
    $regex .= "|";
  }
  $regex .= $regex_annex;
  $regex .= ")\$";
  $regex =~ s/\[\^/\[\\\^/g;
  return $regex;
}

# This function takes a reference to a hashtable and a ratio as its arguments.
# The hashtable represents the names and sizes of the buckets available to
# make the solution, and the ratio represents the percentage of the total
# of all the bucket sizes that the solution must represent.
# This function returns a list, representing the solution to the proplem
# presented to it, in the following format:
# The last element is the ratio by which one of the buckets must be further
# subdivided.  If an exact solution was found, then this ratio will be
# undefined.
# If the last element is defined, the next to last element will be the name
# of the bucket which needs to be subdivided by the ratio indicated therein.
# The rest of the list returned contains the names of the buckets which will
# go into the solution.
# This explanation is a little confusing, and since the action of this function
# is so central to the working of this module, I'll give an example to help
# clear things up.  Let's say the hash you pass in looks like this:
# { 'a' => 4, 'b' => 2, 'c' => 4 }
# If the ratio given is .6, then a valid return from the function will be:
# ('a', 'b', undef), since the combination of the 'a' and 'b' buckets adds
# up exactly to 60% of the total of all the buckets.  However, if the ratio
# asked for is .5, then the return would probably be:
# ('a', 'b', .5), since the only way to get 50% of the total is to take 
# all of the 'a' bucket and half of the 'b' bucket.
# I hope that clears things up.

sub _make_list {

  my($hashref, $ratio) = @_;

  my(@values) = values(%{$hashref});
  my($target,$max) = (0,0);

  # Here we figure out some attributes of the data we've been given -- what
  # amount we're shooting for, and what the larget value is.
  foreach (@values) { 
    die "Non-number found: $_\n" unless /^\d+$/;
    $target += $_;
    if ($_ > $max) { $max = $_ }
  }
  $target *= $ratio;
  $target = int($target);

  # Once we have an understanding of the data we're working with, we can
  # start trying to find a good solution.  The first thing we do is
  # try to solve the problem with no bounds -- having the third argument
  # at $max+1 guarantees that all of the buckets will be considered
  # for inclusion.  The first returned value is a reference to a hash
  # describing the solution and the second is a somewhat arbitrary "score"
  # which describes how "good" that solution is.  While the score is not
  # really a good metric of anything realistic, it roughly decreases as
  # the quality of the solution increases, and reaches 0 as the solution
  # become perfect (requiring no further subdivison).
  my($besthash, $bestscore) = _find_soln(\@values, $target, $max+1);

  # So, if on our first try, we get a score of 0, we just return the
  # solution with an undef ratio.
  if ($bestscore == 0) { return (_get_words($besthash, $hashref), undef) }
  my($ref,$score) = ("",0);

  # If the first solution wasn't perfect, then the theory is that maybe it
  # didn't do very well because it included a bucket it shouldn't have.  So
  # what we do is try re-making the solution a number of times, excluding
  # a number of different buckets each time, until we either come up with a
  # perfect solution or run out of things to try.  This is almost certainly
  # not the best way to go about things, but it works, so I'm not going to
  # worry about it until the next version.  If then.  :)
  foreach $max (keys %{$besthash}) {
    ($ref, $score) = _find_soln(\@values, $target, $max);
    next unless defined $ref;
    if ($score == 0) { return (_get_words($ref, $hashref), undef) }
    if ($score < $bestscore) { $bestscore = $score; $besthash = $ref }
  }
  return (_get_words($besthash, $hashref, $target));
}

# This function takes as inputs a list of values, a target total to aim for and
# a maximum bucket size to use.  It then constructs a suitable combination of
# the values it was given to get as close to the target as possible without
# using any values that aren't smaller than the max.  It doesn't do it very
# well.
# It returns a solution hash and a score for the "goodness" of that solution.
sub _find_soln {
  my($ref, $target, $max) = @_;
  my($val,$sum) = (0,0);
  my(%soln) = ();
  my(%left) = ();

  foreach $val (sort {$b <=> $a} @{$ref}) {
    next unless $val < $max;
    if ($val + $sum <= $target) {
      $sum += $val;
      $soln{$val}++;
    }
    else {
      $left{$val}++;
    }
  }
  my($diff) = $target - $sum;
  my($min)  = (sort {$b <=> $a} keys %left)[-1];
  unless (defined $min) { return undef }
  my($score)= $diff * $min;
  return (\%soln, $score);
}

# This function takes a solution hash as returned from _find_soln, the data
# hash as given to _make_list and an optional target, and returns a list
# appropriate to be returned by _make_list.  Its action is uninteresting and
# straightforward, so I will not waste bytes in describing it further.
sub _get_words {
  my($soln, $data, $target) = @_;
  my(@retarray) = ();
  my($total,%left) = (0,%{$data});

  foreach my $solkey (keys %{$soln}) {
    foreach my $num (1..$soln->{$solkey}) {
      foreach my $datkey (keys %left) {
        if ($data->{$datkey} == $solkey) {
          push(@retarray, $datkey);
          delete($left{$datkey});
          $total += $solkey;
          last;
        }
      }
    }
  }
  if (defined $target) {
    my($minkey) = "";
    my($min) = (sort {$a <=> $b} values %{$data})[-1];
    foreach my $leftkey (keys %left) {
      if ($min >= $data->{$leftkey}) {
        $minkey = $leftkey;
        $min    = $data->{$leftkey};
      }
    }
    push(@retarray,($minkey, (($target - $total)/$min)));
  }
  return @retarray;
}

# Simple test for numericity, pulled straight from the FAQ.
sub _is_numeric {
  my($test) = shift;

  unless ($test =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/) {
    return undef;
  }
  return $test;
}

# Used to return polite errors from the module.
sub _whine { 
  my($msg) = shift; 

  if ($^W) { 
    warn("String::REPartition says: $msg\n"); 
  }
  return undef; 
}

# Given a list of numbers, sorts it and combines contiguous members into
# comma-separated pairs.  That is, turns (1 2 3 4 7 8) into (1,4 7,8).  This
# is useful in building a nice-looking regular expression.
sub _shrink_list {
  my(@list) = sort {$a <=> $b} @_;
  my($num) = 0;

  until ($num >= $#list) {
    if ((split(',',$list[$num]))[-1] == ($list[$num+1]-1)) {
      if ($list[$num] =~ /^\d+$/) {
        $list[$num] .= "," . splice(@list,$num+1,1);
      }
      else {
        substr($list[$num],index($list[$num],",")+1) = splice(@list,$num+1,1);
      }
    }
    else {
      $num++;
    }
  }
  return @list;
}

1;

__END__

=head1 NAME

String::REPartition - Generates a regex to partition a data set

=head1 SYNOPSIS

  use String::REPartition;
  use strict;

  my($regex) = make_partition_re(0.5, \@some_really_big_list_of_strings);
  if ($string =~ /$regex/) {
    # $string is in the first half of the data
  } else {
    # $string is in the second half
  }


=head1 DESCRIPTION

This module exports a single function -- make_partition_re.  It takes as its
first argument a number between 0 and 1, representing a percentage, and as
its second argument a reference to a list of strings.  It returns a regular
expression which is guaranteed to match the percentage of the strings in
the list represented by the number in the first argument.  More importantly,
the regex returned will *not* to match the rest of the string in the
list.  That is, if the inputs were '0.6' and a reference to a list of 100
strings, the returned regex would match 60 of the strings in the list and not
match the other 40. 

Keep in mind that, since only integer operations may be performed on these
strings, (that is, there cannot be a regex which matches a fraction of a
string), the target number is rounded down.  If you have 4 strings in your
list and a ratio of 0.4, the resulting regex will match 1 string, not 1.6
strings.  More interestingly, with 4 strings and a ratio of 0.1, the
resulting regex will almost certainly be C</^()$/> -- matching exactly 0 of
the strings in the list.  Furthermore, because of this rounding, the
returned regex may not match precisely the number expected by multiplying
the size of the list by the ratio, but instead be off by a small number
in either direction.

c<make_partition_re()> will return c<undef> on a failure, and print a warning
to STDERR if C<$^W> is true.  Currently, the only errors that can occur relate
directly to the validity of the inputs.  Furthermore, if the strings in the
list are not unique, the behaviour of this function is not defined.  For a
small amout of repetition the regex should still work, but it should be clear 
that a solution cannot be found if the input list consists only of many copies
of the same string.

The function finds its solution in roughly O(N) time -- however, in worst cases,
I think it can get as high as O(N^2).  It's also true that certain types
of pathologically constructed data sets can break things and cause it either to
return an invalid regex or to enter an infinite loop.  While I haven't run
into any of this in my testing, I'm not confident that I've tested every
possibility.

So why would you want to use this?  Well, that's a question you'll have to
answer for yourself, mostly.  :)  However, the situations I envisaged while
developing the module were sort of like this: Imagine you have a large set of
data, indexed by a correspondingly large set of keywords.  Let's say you want 
to split this data into two partitions, perhaps in order to store the data 
in two separate locations.  Maintaining a complete list of the remote keys
could be expensive -- instead, you can simply store a regular expression
which matches the keys you keep remotely and does not match the local ones.

Another interesting feature is that a regex generated from a sufficiently 
large subset of your data will, approximately, match the appropriate percentage
of strings from the complete data set.  This means that you do not need to have
all of the data before you generate a regex to partition it.  As an example,
generating a regex from roughly 10% of the words in /usr/dict/words (selected
randomly) gave me a regex that matched within .3% of the desired result for all
of the words.

=head1 Methods

=over 4

=item make_partition_re

See description for details.

=back

=head1 Future Work

=over 4

=item *

As I indicate above, this module does not perform properly when data with 
non-unique strings is given to it.  I did not feel it was reasonable to
take the time to check the list for uniqueness, so it will happily process
data for which it may not be able to generate a valid solution.  This 
may change in future versions.

=item *

Internal rounding is a problem in some cases.  The sections of the code which
are most responsible for this were rather hastily conceived and no doubt could
be somewhat improved.  However, they are also somewhat confusing and I need to
make this release in order to fix a few bugs.  The rounding problem will be
addressed in the next release.

=back

=head1 AUTHOR

Copyright 2007 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
