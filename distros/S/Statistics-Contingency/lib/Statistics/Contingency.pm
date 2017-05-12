use strict;

package Statistics::Contingency;
{
  $Statistics::Contingency::VERSION = '0.09';
}

#              Correct=Y   Correct=N
#            +-----------+-----------+
# Assigned=Y |     a     |     b     |
#            +-----------+-----------+
# Assigned=N |     c     |     d     |
#            +-----------+-----------+

# accuracy = (a+d)/(a+b+c+d)
# precision = a/(a+b)
# recall = a/(a+c)
# F1 = 2a/(2a + b + c)

# Edge cases:
#  precision(0,0,+,d) = 0
#  precision(a,0,c,d) = 1
#  precision(0,+,c,d) = 0
#     recall(a,b,0,d) = 1
#     recall(0,b,+,d) = 0
#         F1(a,0,0,d) = 1
#         F1(0,+++,d) = 0

use Params::Validate qw(:all);

sub new {
  my $package = shift;
  my $self = bless { validate @_, 
		     {
		      verbose => { type => SCALAR, default => 0 },
		      categories => { type => ARRAYREF|HASHREF },
		     }
		   }, $package;
  
  $self->{$_} = 0 foreach qw(a b c d);
  my $c = delete $self->{categories};
  $self->{categories} = { map {($_ => {a=>0, b=>0, c=>0, d=>0})} 
			  UNIVERSAL::isa($c, 'HASH') ? keys(%$c) : @$c
			};
  return $self;
}

sub set_entries {
  my $self = shift;
  @{ $self }{'a', 'b', 'c', 'd'} = @_;
}

sub add_result {
  my ($self, $assigned, $correct, $name) = @_;
  my $cats_table = $self->{categories};

  # Hashify
  foreach ($assigned, $correct) {
    $_ = {$_ => 1}, next               unless ref $_;
    next                               if UNIVERSAL::isa($_, 'HASH');  # Leave alone
    $_ = { map {($_ => 1)} @$_ }, next if UNIVERSAL::isa($_, 'ARRAY');
    die "Unknown type '$_' for category list";
  }

  # Add to the micro/macro tables
  foreach my $cat (keys %$cats_table) {
    $cats_table->{$cat}{a}++, $self->{a}++ if  $assigned->{$cat} and  $correct->{$cat};
    $cats_table->{$cat}{b}++, $self->{b}++ if  $assigned->{$cat} and !$correct->{$cat};
    $cats_table->{$cat}{c}++, $self->{c}++ if !$assigned->{$cat} and  $correct->{$cat};
    $cats_table->{$cat}{d}++, $self->{d}++ if !$assigned->{$cat} and !$correct->{$cat};
  }

  if ($self->{verbose}) {
    print "$name: assigned=(@{[ keys %$assigned ]}) correct=(@{[ keys %$correct ]})\n";
  }

  # Clear any cached results
  delete $self->{macro};

  $self->{hypotheses}++;
}

sub _invert {
  my ($self, $x, $y) = @_;
  return 1 unless $y;
  return 0 unless $x;
  return 1 / (1 + $y/$x);
}

sub _accuracy {
  my $h = $_[1];
  return 1 unless grep $h->{$_}, qw(a b c d);
  return +($h->{a} + $h->{d}) / ($h->{a} + $h->{b} + $h->{c} + $h->{d});
}

sub _error {
  my $h = $_[1];
  return 0 unless grep $h->{$_}, qw(a b c d);
  return +($h->{b} + $h->{c}) / ($h->{a} + $h->{b} + $h->{c} + $h->{d});
}

sub _precision {
  my ($self, $h) = @_;
  return 0 if $h->{c} and !$h->{a} and !$h->{b};
  return $self->_invert($h->{a}, $h->{b});
}
  
sub _recall {
  my ($self, $h) = @_;
  return $self->_invert($h->{a}, $h->{c});
}
  
sub _F1 {
  my ($self, $h) = @_;
  return $self->_invert(2 * $h->{a}, $h->{b} + $h->{c});
}

# Fills in precision, recall, etc. for each category, and computes their averages
sub _macro_stats {
  my $self = shift;
  return $self->{macro} if $self->{macro};
  
  my @metrics = qw(precision recall F1 accuracy error);

  my $cats = $self->{categories};
  die "No category information has been recorded"
    unless keys %$cats;

  my %results;
  while (my ($cat, $scores) = each %$cats) {
    foreach my $metric (@metrics) {
      my $method = "_$metric";
      $results{$metric} += ($scores->{$metric} = $self->$method($scores));
    }
  }
  foreach (@metrics) {
    $results{$_} /= keys %$cats;
  }
  $self->{macro} = \%results;
}

sub micro_accuracy  { $_[0]->_accuracy( $_[0]) }
sub micro_error     { $_[0]->_error(    $_[0]) }
sub micro_precision { $_[0]->_precision($_[0]) }
sub micro_recall    { $_[0]->_recall(   $_[0]) }
sub micro_F1        { $_[0]->_F1(       $_[0]) }

sub macro_accuracy  { shift()->_macro_stats->{accuracy} }
sub macro_error     { shift()->_macro_stats->{error} }
sub macro_precision { shift()->_macro_stats->{precision} }
sub macro_recall    { shift()->_macro_stats->{recall} }
sub macro_F1        { shift()->_macro_stats->{F1} }

sub category_stats {
  my $self = shift;
  $self->_macro_stats;

  return $self->{categories};
}

sub stats_table {
  my $self = shift;
  my $figs = shift || 3;

  my @data = map $self->_sig_figs($_, $figs),
    (
     $self->macro_recall,
     $self->macro_precision,
     $self->macro_F1,
     $self->micro_recall,
     $self->micro_precision,
     $self->micro_F1,
     $self->micro_error,
    );
  
  my $m = 0;  # Max length of @data items
  for (@data) {
    $m = length() if length() > $m;
  }
  my $s = ' ' x ($m - 4);
  
  my $out = "+" . ("-" x (10 + 7*$m)) . "+\n";
  $out   .= "| $s maR $s maP$s maF1  $s miR $s miP$s miF1  $s Err |\n";
  $out   .= "| %${m}s %${m}s %${m}s  %${m}s %${m}s %${m}s  %${m}s |\n";
  $out   .= "+" . ("-" x (10 + 7*$m)) . "+\n";

  return sprintf($out, @data);
}

sub _sig_figs {
  my ($self, $number, $figs) = @_;
  my $after_point = $figs - int ($number != 0 ? log($number)/log(10) : 0);
  return sprintf "%.${after_point}f", $number;
}

1;

__END__

=head1 NAME

Statistics::Contingency - Calculate precision, recall, F1, accuracy, etc.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 use Statistics::Contingency;
 my $s = new Statistics::Contingency(categories => \@all_categories);
 
 while (...something...) {
   ...
   $s->add_result($assigned_categories, $correct_categories);
 }
 
 print "Micro F1: ", $s->micro_F1, "\n"; # Access a single statistic
 print $s->stats_table; # Show several stats in table form

=head1 DESCRIPTION

The C<Statistics::Contingency> class helps you calculate several
useful statistical measures based on 2x2 "contingency tables".  I use
these measures to help judge the results of automatic text
categorization experiments, but they are useful in other situations as
well.

The general usage flow is to tally a whole bunch of results in the
C<Statistics::Contingency> object, then query that object to obtain
the measures you are interested in.  When all results have been
collected, you can get a report on accuracy, precision, recall, F1,
and so on, with both macro-averaging and micro-averaging over
categories.

=head2 Macro vs. Micro Statistics

All of the statistics offered by this module can be calculated for
each category and then averaged, or can be calculated over all
decisions and then averaged.  The former is called macro-averaging
(specifically, macro-averaging with respect to category), and the
latter is called micro-averaging.  The two procedures bias the results
differently - micro-averaging tends to over-emphasize the performance
on the largest categories, while macro-averaging over-emphasizes the
performance on the smallest.  It's often best to look at both of them
to get a good idea of how your data distributes across categories.

=head2 Statistics available

All of the statistics are calculated based on a so-called "contingency
table", which looks like this:

              Correct=Y   Correct=N
            +-----------+-----------+
 Assigned=Y |     a     |     b     |
            +-----------+-----------+
 Assigned=N |     c     |     d     |
            +-----------+-----------+

a, b, c, and d are counts that reflect how the assigned categories
matched the correct categories.  Depending on whether a
macro-statistic or a micro-statistic is being calculated, these
numbers will be tallied per-category or for the entire result set.

The following statistics are available:

=over 4

=item * accuracy

This measures the portion of all decisions that were correct
decisions.  It is defined as C<(a+d)/(a+b+c+d)>.  It falls in the
range from 0 to 1, with 1 being the best score.

Note that macro-accuracy and micro-accuracy will always give the same
number.

=item * error

This measures the portion of all decisions that were incorrect
decisions.  It is defined as C<(b+c)/(a+b+c+d)>.  It falls in the
range from 0 to 1, with 0 being the best score.

Note that macro-error and micro-error will always give the same
number.

=item * precision

This measures the portion of the assigned categories that were
correct.  It is defined as C<a/(a+b)>.  It falls in the range from 0
to 1, with 1 being the best score.

=item * recall

This measures the portion of the correct categories that were
assigned.  It is defined as C<a/(a+c)>.  It falls in the range from 0
to 1, with 1 being the best score.

=item * F1

This measures an even combination of precision and recall.  It is
defined as C<2*p*r/(p+r)>.  In terms of a, b, and c, it may be
expressed as C<2a/(2a+b+c)>.  It falls in the range from 0 to 1, with
1 being the best score.

=back

The F1 measure is often the only simple measure that is worth trying
to maximize on its own - consider the fact that you can get a perfect
precision score by always assigning zero categories, or a perfect
recall score by always assigning every category.  A truly smart system
will assign the correct categories and only the correct categories,
maximizing precision and recall at the same time, and therefore
maximizing the F1 score.

Sometimes it's worth trying to maximize the accuracy score, but
accuracy (and its counterpart error) are considered fairly crude
scores that don't give much information about the performance of a
categorizer.

=head1 METHODS

The general execution flow when using this class is to create a
C<Statistics::Contingency> object, add a bunch of results to it, and
then report on the results.

=over 4

=item * $e = Statistics::Contingency->new()

Returns a new C<Statistics::Contingency> object.  Expects a
C<categories> parameter specifying the entire set of categories that
may be assigned during this experiment.  Also accepts a C<verbose>
parameter - if true, some diagnostic status information will be
displayed when certain actions are performed.

=item * $e->add_result($assigned_categories, $correct_categories, $name)

Adds a new result to the experiment.  The lists of assigned and
correct categories can be given as an array of category names
(strings), as a hash whose keys are the category names and whose
values are anything logically true, or as a single string if there is
only one category.

If you've already got the lists in hash form, this will be the fastest
way to pass them.  Otherwise, the current implementation will convert
them to hash form internally in order to make its calculations
efficient.

The C<$name> parameter is an optional name for this result.  It will
only be used in error messages or debugging/progress output.

In the current implementation, we only store the contingency tables
per category, as well as a table for the entire result set.  This
means that you can't recover information about any particular single
result from the C<Statistics::Contingency> object.

=item * $e->set_entries($a, $b, $c, $d)

If you don't wish to use the c<add_result()> interface, but still take
advantage of the calculation methods and the various edge cases they
handle, you can directly set the four elements of the contingency
table with this method.

=item * $e->micro_accuracy

Returns the micro-averaged accuracy for the data set.

=item * $e->micro_error

Returns the micro-averaged error for the data set.

=item * $e->micro_precision

Returns the micro-averaged precision for the data set.

=item * $e->micro_recall

Returns the micro-averaged recall for the data set.

=item * $e->micro_F1

Returns the micro-averaged F1 for the data set.

=item * $e->macro_accuracy

Returns the macro-averaged accuracy for the data set.

=item * $e->macro_error

Returns the macro-averaged error for the data set.

=item * $e->macro_precision

Returns the macro-averaged precision for the data set.

=item * $e->macro_recall

Returns the macro-averaged recall for the data set.

=item * $e->macro_F1

Returns the macro-averaged F1 for the data set.

=item * $e->stats_table

Returns a string combining several statistics in one graphic table.
Since accuracy is 1 minus error, we only report error since it takes
less space to print.  An optional argument specifies the number of
significant digits to show in the data - the default is 3 significant
digits.

=item * $e->category_stats

Returns a hash reference whose keys are the names of each category,
and whose values contain the various statistical measures (accuracy,
error, precision, recall, or F1) about each category as a hash reference.  For
example, to print a single statistic:

 print $e->category_stats->{sports}{recall}, "\n";

Or to print certain statistics for all categtories:
 
 my $stats = $e->category_stats;
 while (my ($cat, $value) = each %$stats) {
   print "Category '$cat': \n";
   print "  Accuracy: $value->{accuracy}\n";
   print "  Precision: $value->{precision}\n";
   print "  F1: $value->{F1}\n";
 }

=back

=head1 AUTHOR

Ken Williams <kwilliams@cpan.org>

=head1 COPYRIGHT

Copyright 2002-2008 Ken Williams.  All rights reserved.

This distribution is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
