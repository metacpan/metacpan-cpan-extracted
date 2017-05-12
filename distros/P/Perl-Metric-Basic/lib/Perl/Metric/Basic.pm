package Perl::Metric::Basic;
use strict;
use base qw(Class::Accessor);
use Scalar::Util qw(blessed);
__PACKAGE__->mk_accessors(qw());
our $VERSION = '0.31';

sub measure {
  my $self     = shift;
  my $document = shift;

  die "No PPI::Document passed"
    unless blessed($document) && $document->isa('PPI::Document');

  my $metrics;

  # go though all the nodes
  my @packages;
  my $package;
  my @contents;
  foreach my $node ($document->children) {
    if ($node->isa('PPI::Statement::Package')) {
      if (@contents) {
        push @packages,
          {
          package  => $package,
          contents => [@contents],
          };
      }
      $package  = $node;
      @contents = ();
    } else {
      push @contents, $node;
    }
  }
  push @packages,
    {
    package  => $package,
    contents => [@contents],
    };

  foreach my $data (@packages) {
    my $package  = $data->{package};
    my $contents = $data->{contents};

    my $package_name = $self->_package_name($package);

    foreach my $node (@$contents) {
      next unless $node->isa('PPI::Statement::Sub');
      my $sub_name = $node->name;
      my $content  = $node->content;
      my $lines    = $content =~ tr/\n//;

      my $whitespace = join ',',
        map { $_->content } @{ $node->find('PPI::Token::Whitespace') };
      my $lines_of_code = $whitespace =~ tr/\n//;

      my $all_comments = $node->find('PPI::Token::Comment');
      my $comments     = 0;
      $comments = scalar(@$all_comments) if $all_comments;

      my $blank_lines           = 0;
      my $all_nodes             = $node->find(sub { 1 });
      my $last_node_was_newline = 0;
      foreach my $node (@$all_nodes) {
        if ($node->isa('PPI::Token::Whitespace')) {
          my $has_newline = $node->content =~ /\n/;
          if ($has_newline) {
            $blank_lines++ if $last_node_was_newline;
            $last_node_was_newline = 1;
          } else {
            $last_node_was_newline = 0;
          }
        }
      }

      my ($symbols, $symbols_unique) =
        $self->_unique($node->find('PPI::Token::Symbol'));

      my ($numbers, $numbers_unique) =
        $self->_unique($node->find('PPI::Token::Number'));

      my ($words, $words_unique) =
        $self->_unique($node->find('PPI::Token::Word'));

      my ($operators, $operators_unique) =
        $self->_unique($node->find('PPI::Token::Operator'));

      my $metric = {
        blank_lines      => $blank_lines,
        comments         => $comments,
        lines            => $lines,
        lines_of_code    => $lines_of_code,
        numbers          => $numbers,
        numbers_unique   => $numbers_unique,
        operators        => $operators,
        operators_unique => $operators_unique,
        symbols          => $symbols,
        symbols_unique   => $symbols_unique,
        words            => $words,
        words_unique     => $words_unique,
      };

      $metrics->{$package_name}->{$sub_name} = $metric;
    }
  }
  return $metrics;
}

# this should be rolled into PPI
sub _package_name {
  my ($self, $package) = @_;
  my $words = $package->find('PPI::Token::Word');
  return $words->[1]->content;
}

# return the total number of nodes and the number of nodes with unique
# content
sub _unique {
  my ($self, $nodes) = @_;
  return (0, 0) unless $nodes;
  my $count = scalar @$nodes;
  my %count;
  $count{ $_->content }++ foreach @$nodes;
  my $count_unique = (keys %count);
  return ($count, $count_unique);
}

__END__

=head1 NAME

Perl::Metric::Basic - Provide basic software metrics

=head1 SYNOPSIS

  # first construct a PPI::Document object to pass in
  my $document = PPI::Document->load("t/lib/Acme.pm");

  # then retrieve metrics on the document
  my $m = Perl::Metric::Basic->new;
  my $metric = $m->measure($document);

  # $metric will consist of something like:
  #  'Acme' => {
  #    'new' => {
  #      'blank_lines'      => 1,
  #      'comments'         => 1,
  #      'lines'            => 7,
  #      'lines_of_code'    => 6,
  #      'numbers'          => 0,
  #      'numbers_unique'   => 0,
  #      'operators'        => 3,
  #      'operators_unique' => 2,
  #      'symbols'          => 5,
  #      'symbols_unique'   => 2,
  #      'words'            => 7,
  #      'words_unique'     => 6
  #    },
  # ...

=head1 DESCRIPTION

When constructing software one often produces code of vastly differing
quality. The Perl::Metric::Basic module leverages the PPI module to
provide some interesting software metrics for Perl code, mostly
measuring size and maintainability.

A metric is some sort of measurement which is intended to help you
make a decision about a piece of code. There aren't any hard rules
about metrics, but the ones provided should allow you to make
decisions about modules or subroutines which are outliers. Abnormal
measurements in a subroutine are a warning sign that you should
reexamine that routine, checking for unusually low quality.

This module uses the PPI module, and thus can parse Perl code without
evaluating it.

If you're interested in software metrics, I highly recommend "Code
Complete" (Second Edition) by Steve McConnel (Microsoft Press).

=head1 METHODS

=head2 new()

The new() method is the constructor:

  my $m = Perl::Metric::Basic->new;

=head2 measure()

The measure() method measures some metrics and returns a hash
reference. Files in Perl can contain more than one package, and it is
interesting to seperate metrics by package. The key for the hash
reference is the name of the package, and the value is another hash
reference.

Perl packages are seperated into subroutines, and it is interesting to
seperate metrics by subroutine. The key for the second hash reference
is the name of the subroutine, and the value is another hash reference
containing metrics.

There are various metrics applied to the subroutine. The key for the
third hash reference is the name of the metric, and the value is the
value of the metric. The metrics are:

=over 4

=item blank_lines

The number of blank code lines.

=item comments

The number of lines containing comments.

=item lines

The total number of lines.

=item lines_of_code

The number of lines of code.

=item numbers

The total number of numbers used (eg "$z = 42 * 3" would have 2
numbers).

=item numbers_unique

The number of unique numbers used (eg "$z = 2*$x + 2*$y" would have 1
unique number).

=item operators

The total number of operators used.

=item operators_unique

The number of unique operators used.

=item symbols

The total number of symbols used (eg "$z = $x*$x + $y*$y" would have 5
symbols).

=item symbols_unique

The number of unique symbols used (eg "$z = $x*$x + $y*$y" would have
3 unique symbols).

=item words

The total number of words (operators) used.

=item words_unique

The number of unique words used.

=back

=head1 NOTES

Currently the code only works for object-oriented classes, not scripts.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004, Leon Brocard

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.
