package Test::Deep::Hashbag 0.002;
# ABSTRACT: A Test::Deep hash comparator ignoring hash keys

use strict;
use warnings;

use Test::Deep::Cmp;

use Data::Dumper;
use Scalar::Util qw(blessed reftype);
use Test::Deep::Hash ();

use Exporter 'import';
our @EXPORT = qw(hashbag superhashbagof);

sub init {
  my $self = shift;
  my $style = shift;
  my @want = @_;

  unless ($style eq 'hashbag' || $style eq 'superhashbag') {
    require Carp;
    Carp::confess("Unknown style '$style' requested. How even?!");
  }

  unless (@want % 2 == 0) {
    require Carp;
    Carp::croak("hashbag needs an even list of pairs.");
  }

  my %seen;

  for my $i (0 .. (@want / 2 - 1)) {
    my $idx = $i * 2;
    my $k = $want[$idx];

    # Ignore ignore() and other things
    if (ref $k) {
      unless ((blessed($k) // "") eq 'Test::Deep::Ignore') {
        # Prevent mistakes?
        require Carp;
        Carp::croak("hashbag keys must be simple scalars or a Test::Deep::Ignore (ignore()) object, got: " . reftype($k));
      }

      next;
    }

    if ($seen{$k}++) {
      require Carp;
      Carp::croak("Duplicate key '$k' passed to hashbag()");
    }
  }

  $self->{val} = \@want;
  $self->{style} = $style;

  return;
}

sub descend {
  my $self = shift;
  my $have = shift;

  unless (ref $have eq 'HASH') {
    my $got = Test::Deep::render_val($have);
    $self->data->{diag} = <<EOM;
got    : $got
expect : A hashref
EOM

    return 0;
  }

  my $want_count = (0 + @{$self->{val}}) / 2;
  my $have_count = keys %$have;

  my %required;
  my @unkeyed;

  # Sort the incoming hashbag into a list of required keys/values, and values
  # who's keys are ignore()
  for my $i (0 .. $want_count - 1) {
    my $idx = $i * 2;

    my $k = $self->{val}->[$idx];
    my $v = $self->{val}->[$idx + 1];

    if (ref $k) {
      push @unkeyed, $v;
    } else {
      $required{$k} = $v;
    }
  }

  # Check all our required stuff first
  my %got = map {
    $_ => $have->{$_}
  } grep {
    exists $have->{$_}
  } keys %required;

  # First check required keys/values simply
  my $hcompare = Test::Deep::Hash->new(\%required);
  return 0 unless $hcompare->descend(\%got);

  # Now check every hash value that has an ignore() key
  my @tocheck = map {
    +{
      k => $_,
      v => $have->{$_}
    }
  } grep { ! exists $required{$_} } keys %$have;

  if ($self->{style} eq 'hashbag' && @tocheck == 0) {
    # hashbag() and no input keys left? We're good!
    return 1;

  } elsif ($self->{style} eq 'hashbag' && @tocheck != @unkeyed) {
    # With hashbag(), we must have as many items left over as we have unkeyed
    # matchers to check against
    my $ecount = 0+@unkeyed;
    my $gcount = 0+@tocheck;

    # Turn keys into sorted list of keys with single quotes around them,
    # escape \ and ' so "foo'bar" looks like 'foo\'bar'. This should make
    # understanding output easier if we need to diag something.
    my $tocheck_desc = join(", ",
      map {
        my $k = $_->{k};
        $k =~ s/(\\|')/\\$1/g;
        "'$k'"
      } sort { $a->{k} cmp $b->{k} } @tocheck
    );

    $self->data->{diag} = <<EOM;
We expected $ecount ignored() keys, but we found $gcount keys left?
Remaining keys: $tocheck_desc
EOM

    return 0;

  } elsif ($self->{style} eq 'superhashbag' && @unkeyed == 0) {
    # superhashbagof() and no matchers left? We're good
    return 1;
  }

  my %match_by_got;
  my %match_by_want;

  # Expensiveish ... check every expect against every got once
  for my $i (0..$#unkeyed) {
    my $want = $unkeyed[$i];

    for my $j (0..$#tocheck) {
      if (Test::Deep::eq_deeply_cache($tocheck[$j]->{v}, $unkeyed[$i])) {
        $match_by_got{$j}{$i} = 1;
        $match_by_want{$i}{$j} = 1;
      }
    }
  }

  # Now, imagine we have:
  #
  #   cmp_deeply(
  #     {
  #       laksdjfaf  => 'bob',
  #       xlaksdjfaf => 'bobby',
  #     },
  #     hashbag(
  #       ignore() => re('.*b'),
  #       ignore() => re('.*b.*bb'),
  #     ),
  #     'got our matching resp',
  #   );
  #
  # %match_by_got might look like:
  #
  #   {
  #     0 => {    # 0th got  (bob)
  #       0 => 1, # 1st want ('.*b')
  #     },
  #     1 => {    # 1st got  (bobby)
  #       0 => 1, # 0th want ('.*b')
  #       1 => 1, # 1st want ('.*b.*bb')
  #     },
  #   }
  #
  # Sometimes, matches can match multiple things, and we need to be sure
  # that each matcher is used only once. To do this we, we'll create a
  # directed graph, and then use the Edmonds-Karp algorithm to find the
  # maximum flow of the graph. If the maximum flow is equal to our number of
  # items, we know we found a case where each item matched at least once.
  #
  # In the data above, our gots are g0 (bob) and g1 (bobby), and our matchers
  # are m0 ('.*b'), and m1 ('.*b.*bb'). Our graph will look like
  #
  #            -> g0
  #          /       \
  #   source           -> m0 --> sink
  #          \       /       /
  #            -> g1 ---> m1

  my $max_flow_found = 0;

  my %matchers_used = map { $_ => 0 } 0..$#unkeyed;

  if (%match_by_got) {
    my %graph;

    for my $g (keys %match_by_got) {
      $graph{source}{"g$g"} = 1;

      for my $m (keys %{$match_by_got{$g}}) {
        $graph{"g$g"}{"m$m"} = 1;
      }
    }

    for my $m (keys %match_by_want) {
      $graph{"m$m"}{sink} = 1;
    }

    # Generate a flow graph where each edge from the source *should* have
    # a weight of 0 if it was used
    $max_flow_found = max_flow(\%graph);

    for my $g (keys %match_by_got) {
      if ($graph{source}{"g$g"} == 0) {
        # Record that in our best case (highest flow) this key matched; to be
        # used in diagnostics later
        $tocheck[$g]{matched} = 1;
      }
    }

    for my $m (keys %match_by_want) {
      if ($graph{"m$m"}{sink} == 0) {
        # Record that in our best case (highest flow) this matcher matched; to be
        # used in diagnostics later
        $matchers_used{$m} = 1;
      }
    }

    # With hashbag() there are as many items to check as there are @unkeyed.
    # With superhashbagof(), @unkeyed is the matchers we need to match, and
    # there may be many more items to check against, but max flow can only
    # go up to @unkeyed. In both cases, if max flow == unkeyed, we're good.
    return 1 if $max_flow_found == @unkeyed;
  }

  my @keys_had_no_match = map { $_->{k} } grep { ! $_->{matched} } @tocheck;

  # Turn keys into sorted list of keys with single quotes around them,
  # escape \ and ' so "foo'bar" looks like 'foo\'bar'. This should make
  # understanding output easier
  my $keys_desc = join(", ",
    map {
      my $k = $_;
      $k =~ s/(\\|')/\\$1/g;
      "'$k'"
    } sort @keys_had_no_match
  );

  my @matchers_had_no_match = map { $unkeyed[$_] } grep {
    ! $matchers_used{$_}
  } keys %matchers_used;

  my $matchers_desc = "\n" . Dumper(\@matchers_had_no_match);

  my $wanted_flow = @unkeyed;

  $self->data->{diag} = <<EOM;
Failed to find all required items in the remaining hash keys.
Expected to match $wanted_flow items, best case match was $max_flow_found.
Keys with no match: $keys_desc
Matchers that failed to match:$matchers_desc
EOM

  return 0;
}

sub diagnostics {
  my ($self, $where, $last) = @_;
  my $diag;

  if ($self->data->{diag}) {
    $diag = "Comparing $where\n" . $self->data->{diag};
  } else {
    $diag = $last->{diag};
    $diag =~ s/\$data/$where what/;
  }

  return $diag;
}

sub hashbag {
  return Test::Deep::Hashbag->new('hashbag', @_);
}

sub superhashbagof {
  return Test::Deep::Hashbag->new('superhashbag', @_);
}

# Adapted https://en.wikipedia.org/wiki/Ford%E2%80%93Fulkerson_algorithm#Python_implementation_of_the_Edmonds%E2%80%93Karp_algorithm
sub bfs {
  my ($graph, $source, $sink, $parent) = @_;

  my %visited;

  my @todo = $source;

  while (@todo) {
    my $item = pop @todo;

    for my $v (keys $graph->{$item}->%*) {
      next unless $graph->{$item}{$v};

      next if $visited{$v}++;

      $parent->{$v} = $item;

      push @todo, $v;
    }
  }

  return !! $visited{$sink};
}

sub max_flow {
  my ($graph) = @_;

  my $max_flow = 0;

  my $parent = {};

  while (bfs($graph, 'source', 'sink', $parent)) {
    my $c = 'sink';

    # No way we're hitting a flow this high
    my $path_flow = 'Inf';

    # Find our lowest flow
    while ($c && $c ne 'source') {
      my $pc = $parent->{$c};

      $path_flow = $graph->{$pc}{$c} if $graph->{$pc}{$c} < $path_flow;

      $c = $pc;
    }

    $max_flow += $path_flow;

    $c = 'sink';

    # Adjust flow bidirectionally from our found path
    while ($c && $c ne 'source') {
      my $pc = $parent->{$c};
      $graph->{$pc}{$c} -= $path_flow;
      $graph->{$c}{$pc} += $path_flow;
      $c = $pc;
    }
  }

  return $max_flow;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Test::Deep::Hashbag - A Test::Deep hash comparator ignoring hash keys

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Test::More;
  use Test::Deep;
  use Test::Deep::Hashbag;

  cmp_deeply(
    {
      cat  => 'meow',
      dog  => 'bark bark',
      fish => 'blub',
    },
    hashbag(
      ignore() => 'meow',
      ignore() => re('.*bark.*'),
      fish     => 'blub',
    ),
    'our animals sound about right',
  );

  done_testing;

=head1 DESCRIPTION

This module provides C<hashbag> and C<superhashbagof>, which are like
L<Test::Deep>'s C<bag()> and C<superbagof()>, but for B<hashes>.

The idea is it lets you test that a hash has certain B<values>, but you don't
know or care what the keys are for those specific values.

=head1 EXPORTS

=head2 hashbag

  cmp_deeply(\%got, hashbag(key => 'val', ignore() => 'val2', ...), $desc);

Takes a list of pairs that are expected to be keys and values. For any keys
that aren't C<ignore()>, those keys must exist and have the values provided
(this will be checked first).

The remaining values (where the keys are C<ignore()>) will then be checked
against the left over values in the input hash.

On failure, the diagnostics will show how many unkeyed items were expected to
match, and how many did match in the best possible case. Any keys that
matches could not be found for will be printed out, as will any matchers that
were not used in this best case.

=head2 superhashbagof

  cmp_deeply(\%got, superhashbagof(k => 'v', ignore() => 'v2', ...), $desc);

Like C<hashbag> above, but C<%got> may have extra keys/values in it that we
don't care about.

=head1 NOTES

B<Diagnostic output variability>

With complex matches, the printed information may seem misleading; it can
provide different lists of keys or matchers that didn't match on reruns of
the test. This indicates that some of the matchers can match multiple keys,
and during different test runs they did so in the best case scenario as the
matching order is not deterministic.

B<Performance on large data sets>

With larger and larger amounts of values to test, matching will get slower
and slower, due to how this module works (testing every expected element
against every input). In the future there will be changes to speed up the
simple best/worst cases, but there will always be inherent slowness with
large amounts of data. Use with caution.

=head1 SEE ALSO

L<Test::Deep>

=head1 THANKS

Thanks to rjbs for pointing out a better algorithm than what I had
originally, and to waltman for Graph::MaxFlow which implemented the harder
bits of it (until I replaced Graph / Graph::MaxFlow with my own implementation
to avoid dependencies :)).

=head1 AUTHOR

Matthew Horsfall <wolfsage@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod   use strict;
#pod   use warnings;
#pod
#pod   use Test::More;
#pod   use Test::Deep;
#pod   use Test::Deep::Hashbag;
#pod
#pod   cmp_deeply(
#pod     {
#pod       cat  => 'meow',
#pod       dog  => 'bark bark',
#pod       fish => 'blub',
#pod     },
#pod     hashbag(
#pod       ignore() => 'meow',
#pod       ignore() => re('.*bark.*'),
#pod       fish     => 'blub',
#pod     ),
#pod     'our animals sound about right',
#pod   );
#pod
#pod   done_testing;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides C<hashbag> and C<superhashbagof>, which are like
#pod L<Test::Deep>'s C<bag()> and C<superbagof()>, but for B<hashes>.
#pod
#pod The idea is it lets you test that a hash has certain B<values>, but you don't
#pod know or care what the keys are for those specific values.
#pod
#pod =head1 EXPORTS
#pod
#pod =head2 hashbag
#pod
#pod   cmp_deeply(\%got, hashbag(key => 'val', ignore() => 'val2', ...), $desc);
#pod
#pod Takes a list of pairs that are expected to be keys and values. For any keys
#pod that aren't C<ignore()>, those keys must exist and have the values provided
#pod (this will be checked first).
#pod
#pod The remaining values (where the keys are C<ignore()>) will then be checked
#pod against the left over values in the input hash.
#pod
#pod On failure, the diagnostics will show how many unkeyed items were expected to
#pod match, and how many did match in the best possible case. Any keys that
#pod matches could not be found for will be printed out, as will any matchers that
#pod were not used in this best case.
#pod
#pod =head2 superhashbagof
#pod
#pod   cmp_deeply(\%got, superhashbagof(k => 'v', ignore() => 'v2', ...), $desc);
#pod
#pod Like C<hashbag> above, but C<%got> may have extra keys/values in it that we
#pod don't care about.
#pod
#pod =head1 NOTES
#pod
#pod B<Diagnostic output variability>
#pod
#pod With complex matches, the printed information may seem misleading; it can
#pod provide different lists of keys or matchers that didn't match on reruns of
#pod the test. This indicates that some of the matchers can match multiple keys,
#pod and during different test runs they did so in the best case scenario as the
#pod matching order is not deterministic.
#pod
#pod B<Performance on large data sets>
#pod
#pod With larger and larger amounts of values to test, matching will get slower
#pod and slower, due to how this module works (testing every expected element
#pod against every input). In the future there will be changes to speed up the
#pod simple best/worst cases, but there will always be inherent slowness with
#pod large amounts of data. Use with caution.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Test::Deep>
#pod
#pod =head1 THANKS
#pod
#pod Thanks to rjbs for pointing out a better algorithm than what I had
#pod originally, and to waltman for Graph::MaxFlow which implemented the harder
#pod bits of it (until I replaced Graph / Graph::MaxFlow with my own implementation
#pod to avoid dependencies :)).
#pod
#pod =cut
