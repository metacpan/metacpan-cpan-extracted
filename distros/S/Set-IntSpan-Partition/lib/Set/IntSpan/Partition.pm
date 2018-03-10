package Set::IntSpan::Partition;
use 5.008000;
use strict;
use warnings;
use base qw(Exporter);
use List::Util qw/min max/;
use List::MoreUtils qw/uniq/;
use List::UtilsBy qw/partition_by nsort_by/;
use List::StackBy;
use Set::IntSpan;

our $VERSION = '0.06';

our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  intspan_partition
  intspan_partition_map
);

sub _uniq (@) {
  my %h;
  return map { $h{$_}++ == 0 ? $_ : () } @_;
}

sub _add {
  my $rest = shift;

  my @parts = map {
    my $old = $_;

    my $right = $rest->diff($old);
    my $left = $old->diff($rest);
    my $both = $old->intersect($rest);

    $rest = $right;

    grep { !$_->empty } $left, $both

  } @_;

  push @parts, $rest unless $rest->empty;
  return @parts;
}

sub intspan_partition {
  my @parts = ();

  @parts = _add($_, @parts) for @_;

  # TODO: It's not really possible to get non-unique
  # items into the list? But play it safe for now.
  return _uniq @parts;
}

sub intspan_partition_map {

  my @intspans = @_;

  my @stacks =
    stack_by { $_->[0] }
    sort { $a->[0] <=> $b->[0] }
    map {
      my $ix = $_;
      map { [ @$_, $ix ] } $intspans[$_]->spans
    } 0 .. $#intspans;

  return unless @stacks;

  my $min_overall = min(map { $_->[0] } map { @$_ } @stacks);
  my $max_overall = max(map { $_->[1] } map { @$_ } @stacks);

  push @{ $stacks[0] },
    [ $min_overall,
      $max_overall + 1, '' ];

  push @stacks,[
    [ $max_overall + 1,
      $max_overall + 1, '' ] ];

  for (my $ix = 0; $ix < @stacks - 1; ++$ix) {

    my $max = min(
      $stacks[$ix+1][0][0] - 1,
      map { $_->[1] } @{ $stacks[$ix] },
    );

    my @current_stack =
      map { [ $_->[0], min($_->[1], $max), $_->[2] ] }
      @{ $stacks[$ix] };

    my @new_stack =
      grep { $_->[0] <= $_->[1] }
      map { [ $max + 1, $_->[1], $_->[2] ] }
      @{ $stacks[$ix] };

    $stacks[$ix] = \@current_stack;

    if ($max + 1 == $stacks[$ix+1][0][0]) {
      push @{ $stacks[$ix+1] }, @new_stack;
    } else {
      splice @stacks, $ix+1, 0, \@new_stack;
    }

  }

  my %h = partition_by {
    join ',', sort { $a cmp $b } uniq map { $_->[2] } @$_
  } grep {
    scalar @$_
  } @stacks;

  # TODO(bh): this could be nicer:

  my %map;
  while (my ($k, $v) = each %h) {
    for my $in (split/,/, $k) {
      my $class = Set::IntSpan->new([map {
        [ $_->[0], $_->[1] ]
      } grep { $_->[2] eq $in } map { @$_ } @$v]);
      push @{ $map{$in} }, $class;
    }
  }

  delete $map{''};

  return %map;
}

1;

__END__

=head1 NAME

Set::IntSpan::Partition - Partition int sets using Set::IntSpan objects

=head1 SYNOPSIS

  use Set::IntSpan::Partition;
  my @partition = intspan_partition( @list );

=head1 DESCRIPTION

Partition sets based on membership in a set of C<Set::IntSpan> objects.

=head1 FUNCTIONS

=over

=item intspan_partition( @list )

Given a set of C<Set::IntSpan> objects, this sub creates the smallest
set of C<Set::IntSpan> objects such that, iff an element was in one or
more of the input sets, it will be in exactly one of the output sets,
and an output set is either a subset of an input set or disjoint with
it.

=item intspan_partition_map( @list )

Returns a hash mapping input object indices to C<Set::IntSpan> objects
which are subsets of the input objects the same way C<intspan_partition>
does. This also uses a faster implementation.

=back

=head1 EXPORTS

C<intspan_partition> and C<intspan_partition_map>.

=head1 CAVEATS

Slow. Patches welcome. I don't like the name C<intspan_partition>,
ideas welcome.

=head1 THANKS

Thanks to Paul Cochrane for his many improvements to this distribution as
part of Neil Bowers' L<http://neilb.org/2014/11/29/pr-challenge-2015.html>.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2008-2015 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
