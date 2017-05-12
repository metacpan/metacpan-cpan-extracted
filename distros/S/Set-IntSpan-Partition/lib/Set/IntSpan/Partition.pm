package Set::IntSpan::Partition;

use 5.008000;
use strict;
use warnings;
use base qw(Exporter);

our $VERSION = '0.02';

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

  use Heap::Simple qw//;
  use List::Util qw/min max/;
  use List::MoreUtils qw/uniq/;

  my $heap = Heap::Simple->new(order => sub {
    my ($x, $y) = @_;
    return 1 if $x->[0] < $y->[0];
    return 0 if $x->[0] > $y->[0];
    return 1 if $x->[1] < $y->[1];
    return 0;
  });
  
  for (my $ix = 0; $ix < @_; ++$ix) {
    my $obj = $_[$ix];
    for ($obj->spans) {
      $heap->insert([ $_->[0], $_->[1], [$ix] ]);
    }
  }

  my @result;

  while (1) {
    my $x = $heap->extract_first;
    my $y = $heap->extract_first;

    last unless defined $x;
    push @result, $x unless defined $y;
    last unless defined $y;

    if ($x->[1] < $y->[0]) {
      push @result, $x;
      $heap->insert($y);
      next;
    }

    my $min = min($x->[1], $y->[0]);
    my $max = max(min($y->[0], $x->[1]), min($x->[1], $y->[1]));
    my $XandY = [ $min, $max, [ @{$x->[2]}, @{$y->[2]} ] ];
    my $prefX = [ $x->[0], $XandY->[0] - 1, $x->[2] ];
    my $suffX = [ $XandY->[1] + 1, $x->[1], $x->[2] ];
    my $onlyY = [ $XandY->[1] + 1, $y->[1], $y->[2] ];
    
    for ($prefX, $suffX, $onlyY, $XandY) {
      next unless $_->[0] <= $_->[1];
      $heap->insert($_);
    }
  }
  
  # group spans back into classes
  my %group;
  for my $item (@result) {
    my $key = join ',', uniq sort @{ $item->[2] };
    push @{ $group{$key} }, $item;
  }
  
  my %map;
  while (my ($k, $v) = each %group) {
    my $class = Set::IntSpan->new([map {
      [ $_->[0], $_->[1] ]
    } @$v]);
    push @{ $map{$_} }, $class for uniq map { @{ $_->[2] } } @$v;
  }
  
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

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2008-2009 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
