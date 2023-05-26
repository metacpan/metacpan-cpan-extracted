package Music::CreatingRhythms;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Combinatorial algorithms to generate rhythms

our $VERSION = '0.0802';

use Moo;
use strictures 2;
use Algorithm::Combinatorics qw(permutations);
use Data::Munge qw(list2re);
use Integer::Partition ();
use List::Util qw(all any);
use Math::Sequence::DeBruijn qw(debruijn);
use Module::Load::Conditional qw(check_install);
use Music::AtonalUtil ();
use namespace::clean;

use if defined check_install(module => 'Math::NumSeq::SqrtContinued'),
    'Math::NumSeq::SqrtContinued';


has verbose => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);



sub b2int {
    my ($self, $sequences) = @_;
    my @intervals;
    for my $i (@$sequences) {
        my $string = join '', @$i;
        push @intervals, [ map { length $_ } grep { $_ } split /(10*)/, $string ];
    }
    return \@intervals;
}


sub cfcv {
    my ($self, @terms) = @_;

    my $p0 = 0;
    my $p1 = 1;
    my $p2;
    my $q0 = 1;
    my $q1 = 0;
    my $q2;

    for my $t (@terms) {
      $p2 = $t * $p1 + $p0;
      $q2 = $t * $q1 + $q0;
      $p0 = $p1;
      $p1 = $p2;
      $q0 = $q1;
      $q1 = $q2;
    }

    return [ $p2, $q2 ];
}


sub cfsqrt {
    my ($self, $n, $m) = @_;
    $m ||= $n;
    my @terms;

    my $seq = Math::NumSeq::SqrtContinued->new(sqrt => $n);
    for my $i (1 .. $m) {
        my ($j, $value) = $seq->next;
        push @terms, $value;
    }
    return \@terms;
}


sub chsequl {
    my ($self, $t, $p, $q, $n) = @_;
    die "Usage: chsequl(\$type, \$numerator, \$denominator [\$terms])\n"
        unless $t && defined $p && defined $q;
    $n ||= $p + $q;
    my @word;
    my $i = 0;
    while ($i < $n) {
        push @word, $t eq 'u' ? 1 : 0;
        $i++;
        my ($x, $y) = ($p, $q);
        while ($x != $y && $i < $n) {
            if ($x > $y) {
                push @word, 1;
                $y += $q;
            }
            else {
                push @word, 0;
                $x += $p;
            }
            $i++;
        }
        if ($x == $y && $i < $n) {
            push @word, $t eq 'u' ? 0 : 1;
            $i++;
        }
    }
    return \@word;
}


sub comp {
    my ($self, $n) = @_;
    my @compositions;
    my @parts;
    my $i = 0;
    _compose($n - 1, 1, 0, \$i, \@compositions, \@parts);
    return \@compositions;
}

sub _compose {
    my ($n, $p, $k, $i, $compositions, $parts) = @_;
    if ($n == 0) {
        while ($n < $k) {
            push @{ $compositions->[$$i] }, $parts->[$n];
            $n++;
        }
        push @{ $compositions->[$$i] }, $p;
        $$i++;
        return;
    }
    $parts->[$k] = $p;
    _compose($n - 1, 1, $k + 1, $i, $compositions, $parts);
    _compose($n - 1, $p + 1, $k, $i, $compositions, $parts);
}


sub compa {
    my ($self, $n, @intervals) = @_;
    my @compositions;
    my @parts;
    my $i = 0;
    _composea($n - 1, 1, 0, \$i, \@compositions, \@parts, \@intervals);
    return \@compositions;
}

sub _composea {
  my ($n, $p, $k, $i, $compositions, $parts, $intervals) = @_;
  if ($n == 0) {
    if (_allowed($p, $intervals)) {
      while ($n < $k) {
        push @{ $compositions->[$$i] }, $parts->[$n];
        $n++;
      }
      push @{ $compositions->[$$i] }, $p;
      $$i++;
    }
    return;
  }
  if (_allowed($p, $intervals)) {
    $parts->[$k] = $p;
    _composea($n - 1, 1, $k + 1, $i, $compositions, $parts, $intervals);
  }
  _composea($n - 1, $p + 1, $k, $i, $compositions, $parts, $intervals);
}


sub compam {
    my ($self, $n, $m, @intervals) = @_;
    $m--;
    my @compositions;
    my @parts;
    my $i = 0;
    _composeam($n - 1, 1, 0, $m, \$i, \@compositions, \@parts, \@intervals);
    return \@compositions;
}

sub _composeam {
  my ($n, $p, $k, $m, $i, $compositions, $parts, $intervals) = @_;
  if ($n == 0) {
    if ($k == $m && _allowed($p, $intervals)) {
      while ($n < $k) {
        push @{ $compositions->[$$i] }, $parts->[$n];
        $n++;
      }
      push @{ $compositions->[$$i] }, $p;
      $$i++;
    }
    return;
  }
  if ($k < $m && _allowed($p, $intervals)) {
    $parts->[$k] = $p;
    _composeam($n - 1, 1, $k + 1, $m, $i, $compositions, $parts, $intervals);
  }
  _composeam($n - 1, $p + 1, $k, $m, $i, $compositions, $parts, $intervals);
}


sub compm {
    my ($self, $n, $m) = @_;
    $m--;
    my @compositions;
    my @parts;
    my $i = 0;
    _composem($n - 1, 1, 0, $m, \$i, \@compositions, \@parts);
    return \@compositions;
}

sub _composem {
    my ($n, $p, $k, $m, $i, $compositions, $parts) = @_;
    if ($n == 0) {
        if ($k == $m) {
            while ($n < $k) {
                push @{ $compositions->[$$i] }, $parts->[$n];
                $n++;
            }
            push @{ $compositions->[$$i] }, $p;
            $$i++;
        }
        return;
    }
    if ($k < $m) {
        $parts->[$k] = $p;
        _composem($n - 1, 1, $k + 1, $m, $i, $compositions, $parts);
    }
    _composem($n - 1, $p + 1, $k, $m, $i, $compositions, $parts);
}


sub compmrnd {
    my ($self, $n, $m) = @_;
    return [0] unless $n;
    my @compositions;
    my ($p, $j, $np);
    for(my $mp = $m - 1, $np = $n - 1, $j = 1; $mp > 0; --$np) {
        $p = $mp / $np;
        if ($p % 2 == 0) {
            push @compositions, $j;
            $mp--;
            $j = 1;
        }
        else {
            $j++;
        }
    }
    push @compositions, $j + $np;
    return \@compositions;
}


sub comprnd {
    my ($self, $n) = @_;
    return [0] unless $n;
    my @compositions;
    my $p = 1;
    for my $i (1 .. $n - 1) {
        if ((int rand 2) % 2 == 0) {
            $p++;
        }
        else {
            push @compositions, $p;
            $p = 1;
        }
    }
    push @compositions, $p;
    return \@compositions;
}


sub count_ones {
    my ($self, $n) = @_;
    my $x = 0;
    if (ref $n) {
        for my $i (@$n) {
            $x++ if $i == 1;
        }
    }
    else {
        $x = $n =~ tr/1//;
    }
    return $x;
}


sub count_zeros {
    my ($self, $n) = @_;
    my $x = 0;
    if (ref $n) {
        for my $i (@$n) {
            $x++ if $i == 0;
        }
    }
    else {
        $x = $n =~ tr/0//;
    }
    return $x;
}


sub de_bruijn {
    my ($self, $n) = @_;
    my $sequence = $n ? debruijn([1,0], $n) : 0;
    return [ split //, $sequence ];
}


sub euclid {
    my ($self, $n, $m) = @_;
    my $intercept = 1;
    my $slope = $n / $m;
    my @pattern = ('0') x $m;
    for my $y ( 1 .. $n ) {
        $pattern[ sprintf '%.0f', ( $y - $intercept ) / $slope ] = '1';
    }
    return \@pattern;
}


sub int2b {
    my ($self, $intervals) = @_;
    my @sequences;
    for my $i (@$intervals) {
        my @bitstring;
        for my $j (@$i) {
            my $bits = '1' . '0' x ($j - 1);
            push @bitstring, split //, $bits;
        }
        push @sequences, \@bitstring;
    }
    return \@sequences;
}


sub invert_at {
    my ($self, $n, $parts) = @_;
    my @head = @$parts[ 0 .. $n - 1 ];
    my @tail = map { $_ ? 0 : 1 } @$parts[ $n .. $#$parts ];
    my @data = (@head, @tail);
    return \@data;
}


sub neck {
    my ($self, $n) = @_;
    my @necklaces;
    my @parts = (1);
    my $i = 0;
    _neckbin($n, 1, 1, \$i, \@necklaces, \@parts);
    return \@necklaces;
}

sub _neckbin {
    my ($n, $k, $l, $i, $necklaces, $parts) = @_;
    # k = length of necklace
    # l = length of longest prefix that is a lyndon word
    if ($k > $n) {
        if(($n % $l) == 0) {
            for $k (1 .. $n) {
                push @{ $necklaces->[$$i] }, $parts->[$k];
            }
            $$i++;
        }
    }
    else {
        $parts->[$k] = $parts->[ $k - $l ];
        if ($parts->[$k] == 1) {
            _neckbin($n, $k + 1, $l, $i, $necklaces, $parts);
            $parts->[$k] = 0;
            _neckbin($n, $k + 1, $k, $i, $necklaces, $parts);
        }
        else {
            _neckbin($n, $k + 1, $l, $i, $necklaces, $parts);
        }
    }
}


sub necka {
    my ($self, $n, @intervals) = @_;
    my @necklaces;
    my @parts = (1);
    my $i = 0;
    _neckbina($n, 1, 1, 1, \$i, \@necklaces, \@parts, \@intervals);
    return \@necklaces;
}

sub _neckbina {
    my ($n, $k, $l, $p, $i, $necklaces, $parts, $intervals) = @_;
    if ($k > $n) {
      if (($n % $l) == 0 && _allowed($p, $intervals) && $p <= $n) {
        for $k (1 .. $n) {
          push @{ $necklaces->[$$i] }, $parts->[$k];
        }
        $$i++;
      }
    }
    else {
        $parts->[$k] = $parts->[ $k - $l ];
        if ($parts->[$k] == 1) {
            if (_allowed($p, $intervals) || $k == 1) {
              _neckbina($n, $k + 1, $l, 1, $i, $necklaces, $parts, $intervals);
            }
            $parts->[$k] = 0;
            _neckbina($n, $k + 1, $k, $p + 1, $i, $necklaces, $parts, $intervals);
        }
        else {
            _neckbina($n, $k + 1, $l, $p + 1, $i, $necklaces, $parts, $intervals);
        }
    }
}


sub neckam {
    my ($self, $n, $m, @intervals) = @_;
    my @necklaces;
    my @parts = (1);
    my $i = 0;
    _neckbinam($n, 1, 1, 0, 1, $m, \$i, \@necklaces, \@parts, \@intervals);
    return \@necklaces;
}

sub _neckbinam {
    my ($n, $k, $l, $q, $p, $m, $i, $necklaces, $parts, $intervals) = @_;
    if ($k > $n) {
        if(($n % $l) == 0 && _allowed($p, $intervals) && $p <= $n && $q == $m) {
            for $k (1 .. $n) {
                push @{ $necklaces->[$$i] }, $parts->[$k];
            }
            $$i++;
        }
    }
    else {
        $parts->[$k] = $parts->[ $k - $l ];
        if ($parts->[$k] == 1) {
            if (_allowed($p, $intervals) || $k == 1) {
                _neckbinam($n, $k + 1, $l, $q + 1, 1, $m, $i, $necklaces, $parts, $intervals);
            }
            $parts->[$k] = 0;
            _neckbinam($n, $k + 1, $k, $q, $p + 1, $m, $i, $necklaces, $parts, $intervals);
        }
        else {
            _neckbinam($n, $k + 1, $l, $q, $p + 1, $m, $i, $necklaces, $parts, $intervals);
        }
    }
}


sub neckm {
    my ($self, $n, $m) = @_;
    my @necklaces;
    my @parts = (1);
    my $i = 0;
    _neckbinm($n, 1, 1, 0, $m, \$i, \@necklaces, \@parts);
    return \@necklaces;
}

sub _neckbinm {
    my ($n, $k, $l, $p, $m, $i, $necklaces, $parts) = @_;
    # k = length of necklace
    # l = length of longest prefix that is a lyndon word
    # p = number of parts (ones)
    if ($k > $n) {
        if (($n % $l) == 0 && $p == $m) {
            for $k (1 .. $n) {
              push @{ $necklaces->[$$i] }, $parts->[$k];
            }
            $$i++;
        }
    }
    else {
        $parts->[$k] = $parts->[ $k - $l ];
        if ($parts->[$k] == 1) {
            _neckbinm($n, $k + 1, $l, $p + 1, $m, $i, $necklaces, $parts);
            $parts->[$k] = 0;
            _neckbinm($n, $k + 1, $k, $p, $m, $i, $necklaces, $parts);
        }
        else {
            _neckbinm($n, $k + 1, $l, $p, $m, $i, $necklaces, $parts);
        }
    }
}


sub part {
    my ($self, $n) = @_;
    my $i = Integer::Partition->new($n, { lexicographic => 1 });
    my @partitions;
    while (my $p = $i->next) {
        push @partitions, [ sort { $a <=> $b } @$p ];
    }
    return \@partitions;
}


sub parta {
    my ($self, $n, @parts) = @_;
    my $re = list2re @parts;
    my $i = Integer::Partition->new($n, { lexicographic => 1 });
    my @partitions;
    while (my $p = $i->next) {
      push @partitions, [ sort { $a <=> $b } @$p ]
        if all { $_ =~ /^$re$/ } @$p;
    }
    return \@partitions;
}


sub partam {
    my ($self, $n, $m, @parts) = @_;
    my $re = list2re @parts;
    my $i = Integer::Partition->new($n);
    my @partitions;
    while (my $p = $i->next) {
        push @partitions, [ sort { $a <=> $b } @$p ]
          if @$p == $m && all { $_ =~ /^$re$/ } @$p;
    }
    return \@partitions;
}


sub partm {
    my ($self, $n, $m) = @_;
    my $i = Integer::Partition->new($n);
    my @partitions;
    while (my $p = $i->next) {
        push @partitions, [ sort { $a <=> $b } @$p ]
          if @$p == $m;
    }
    return \@partitions;
}


sub permi {
    my ($self, $parts) = @_;
    my @permutations = permutations($parts);
    return \@permutations;
}


sub pfold {
    my ($self, $n, $m, $f) = @_;
    my @sequence;
    my ($j, $k);
    for (my $i = 1; $i <= $n; ++$i) {
      _oddeven($i, \$k, \$j);
      $k = $k % $m;
      my $y = $f & (1 << $k) ? 1 : 0;
      if ((2 * $j + 1) % 4 > 1) {
          $y = 1 - $y;
      }
      push @sequence, $y;
    }
    return \@sequence;
}

# find x and y such that n = 2^x * (2*y+1)
sub _oddeven {
    my ($n, $x, $y) = @_;
    my $k;
    # two's complement of n = -n or ~n + 1
    my $l = $n & -$n; # this is 2^a
    $$y = ($n / $l - 1) / 2;
    for ($k = 0; $l > 1; ++$k) {
        $l >>= 1;
    }
    $$x = $k;

    return;
}


sub reverse_at {
    my ($self, $n, $parts) = @_;
    my @head = @$parts[ 0 .. $n - 1 ];
    my @tail = reverse @$parts[ $n .. $#$parts ];
    my @data = (@head, @tail);
    return \@data;
}


sub rotate_n {
    my ($self, $n, $parts) = @_;
    my $atu = Music::AtonalUtil->new;
    my $sequence = $atu->rotate($n, $parts);
    return $sequence;
}

sub _allowed { # is p one of the parts?
    my ($p, $parts) = @_;
    return any { $p == $_ } @$parts;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::CreatingRhythms - Combinatorial algorithms to generate rhythms

=head1 VERSION

version 0.0802

=head1 SYNOPSIS

  use Music::CreatingRhythms ();
  my $mcr = Music::CreatingRhythms->new;
  my $foo = $mcr->foo('...');

=head1 DESCRIPTION

C<Music::CreatingRhythms> provides the combinatorial algorithms
described in the book, "Creating Rhythms", by Hollos. Many of these
algorithms are ported directly from the C, and are pretty fast. Please
see the links below for more information.

NB: Arguments are sometimes switched between book and software.

Additionally, this module provides utilities that are not part of the
book, but are nonetheless handy.

=head1 ATTRIBUTES

=head2 verbose

  $verbose = $mcr->verbose;

Show progress. * This is not showing anything yet, however.

=head1 METHODS

=head2 new

  $mcr = Music::CreatingRhythms->new;

Create a new C<Music::CreatingRhythms> object.

=head2 b2int

  $intervals = $mcr->b2int($sequences);

Convert binary B<sequences> of the form C<[[1,0],[1,0,0]]> into a set
of intervals of the form C<[[2],[3]]>.

Examples:

  $got = $mcr->b2int([[1,1,0,1,0,0]]);     # [[1,2,3]]
  $got = $mcr->b2int([[1],[1,0],[1,0,0]]); # [[1],[2],[3]]

=head2 cfcv

  $convergent = $mcr->cfcv(@terms);

Calculate a continued fraction convergent given the B<terms>.

Examples:

  $got = $mcr->cfcv(1, 2);       # [3,2]
  $got = $mcr->cfcv(1, 2, 2);    # [7,5]
  $got = $mcr->cfcv(1, 2, 2, 2); # [17,12]

=head2 cfsqrt

  $terms = $mcr->cfsqrt($n);
  $terms = $mcr->cfsqrt($n, $m);

Calculate the continued fraction for C<sqrt(n)> to B<m> digits, where
B<n> and B<m> are integers.

Examples:

  $got = $mcr->cfsqrt(2, 2); # [1,2]
  $got = $mcr->cfsqrt(2, 3); # [1,2,2]
  $got = $mcr->cfsqrt(2, 4); # [1,2,2,2]

=head2 chsequl

  $sequence = $mcr->chsequl($t, $p, $q);
  $sequence = $mcr->chsequl($t, $p, $q, $n);

Generate the upper or lower Christoffel word for B<p> and B<q>.

Arguments:

  t: required type of word (u: upper, l: lower)
  p: required numerator of slope
  q: required denominator of slope
  n: optional number of terms to generate, default: p+q

Examples:

  $got = $mcr->chsequl('l', 11, 5);
  # [0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,1]
  $got = $mcr->chsequl('u', 11, 5);
  # [1,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0]
  $got = $mcr->chsequl('l', 11, 5, 4); # [0,1,1,0];
  $got = $mcr->chsequl('u', 11, 5, 4); # [1,1,1,0];

=head2 comp

  $compositions = $mcr->comp($n);

Generate all compositions of B<n>.

A "composition" is the set of combinatorial "variations" of the
partitions of B<n> with the duplicates removed.

Example:

  $got = $mcr->comp(4);
  # [1,1,1,1],[1,1,2],[1,2,1],[1,3],[2,1,1],[2,2],[3,1],[4]

=head2 compa

  $compositions = $mcr->compa($n, @intervals);

Generate compositions of B<n> with allowed intervals
B<p1, p2, ... pn>.

Here, the "intervals" are the terms of the partition.

Example:

  $got = $mcr->compa(4, 1,2);
  # [[1,1,1,1],[1,1,2],[1,2,1],[2,1,1],[2,2]]

=head2 compam

  $compositions = $mcr->compam($n, $m, @intervals);

Generate compositions of B<n> with B<m> parts and allowed intervals
B<p1, p2, ... pn>.

Here, the "parts" are the number of elements of each interval set.

Example:

  $got = $mcr->compam(4, 3, 1,2); # [[1,1,2],[1,2,1],[2,1,1]]

=head2 compm

  $compositions = $mcr->compm($n, $m);

Generate all compositions of B<n> into B<m> parts.

Again, the "parts" are the number of elements of each interval set.

Example:

  $got = $mcr->compm(4, 2); # [[1,3],[2,2],[3,1]]

=head2 compmrnd

  $composition = $mcr->compmrnd($n);

Generate a random composition of B<n>.

Example:

  $got = $mcr->compmrnd(16, 4); # [6,1,3,6], etc.

=head2 comprnd

  $composition = $mcr->comprnd($n);

Generate a random composition of B<n>.

Example:

  $got = $mcr->comprnd(16); # [1,3,2,1,1,2,1,3,2], etc.

=head2 count_ones

  $count = $mcr->count_ones($n);

Count the number of 1s in a string or vector.

Examples:

  $got = $mcr->count_ones('100110100');         # 4
  $got = $mcr->count_ones([1,0,0,1,1,0,1,0,0]); # 4

=head2 count_zeros

  $count = $mcr->count_zeros($n);

Count the number of 0s in a string or vector.

Examples:

  $got = $mcr->count_zeros('100110100');         # 5
  $got = $mcr->count_zeros([1,0,0,1,1,0,1,0,0]); # 5

=head2 de_bruijn

  $sequence = $mcr->de_bruijn($n);

Generate the largest de Bruijn sequence of order B<n>.

Example:

  $got = $mcr->de_bruijn(3); # [1,1,1,0,1,0,0,0]

=head2 euclid

  $sequence = $mcr->euclid($n, $m);

Generate a Euclidean rhythm given B<n> onsets distributed over B<m>
beats.

Examples:

  $got = $mcr->euclid(1, 4); # [1,0,0,0]
  $got = $mcr->euclid(2, 4); # [1,0,1,0]
  $got = $mcr->euclid(3, 4); # [1,1,0,1]
  $got = $mcr->euclid(4, 4); # [1,1,1,1]

=head2 int2b

  $sequences = $mcr->int2b($intervals);

Convert B<intervals> of the form C<[2,3]> into a set of binary
sequences.

Examples:

  $got = $mcr->int2b([[1,2,3]]);     # [[1,1,0,1,0,0]]
  $got = $mcr->int2b([[1],[2],[3]]); # [[1],[1,0],[1,0,0]]

=head2 invert_at

  $sequence = $mcr->invert_at($n, $parts);

Invert a section of a B<parts> binary sequence at B<n>.

Examples:

    $parts = [qw(1 0 1 0 0)];
    $got = $mcr->invert_at(0, $parts); # [0,1,0,1,1]
    $got = $mcr->invert_at(1, $parts); # [1,1,0,1,1]
    $got = $mcr->invert_at(2, $parts); # [1,0,0,1,1]

=head2 neck

  $necklaces = $mcr->neck($n);

Generate all binary necklaces of length B<n>.

Example:

  $got = $mcr->neck(3); # [1,1,1],[1,1,0],[1,0,0],[0,0,0]

=head2 necka

  $necklaces = $mcr->necka($n, @intervals);

Generate binary necklaces of length B<n> with allowed intervals
B<p1, p2, ... pn>. For these "necklace" class of functions, the word
"intervals" refers to the size of a number given trailing zeros. So
intervals C<1>, C<2>, and C<3> are represented as C<1>, C<1,0>, and
C<1,0,0> respectively.

Example:

  $got = $mcr->necka(4, 1,2); # [1,1,1,1],[1,1,1,0],[1,0,1,0]

=head2 neckam

  $necklaces = $mcr->neckam($n, $m, @intervals);

Generate binary necklaces of length B<n> with B<m> ones, and allowed
intervals B<p1, p2, ... pn>.

Example:

  $got = $mcr->neckam(4, 3, 1,2); # [[1,1,1,0]]

=head2 neckm

  $necklaces = $mcr->neckm($n, $m);

Generate all binary necklaces of length B<n> with B<m> ones.

Example:

  $got = $mcr->neckm(4, 2); # [[1,1,0,0],[1,0,1,0]]

=head2 part

  $partitions = $mcr->part($n);

Generate all partitions of B<n>.

Example:

  $got = $mcr->part(4); # [1,1,1,1],[1,1,2],[2,2],[1,3],[4]

=head2 parta

  $partitions = $mcr->parta($n, @intervals);

Generate all partitions of B<n> with allowed intervals
B<p1, p2, ... pn>.

Example:

    $got = $mcr->parta(4, 1,2); # [1,1,1,1],[1,1,2],[2,2]

=head2 partam

  $partitions = $mcr->partam($n, $m, @intervals);

Generate all partitions of B<n> with B<m> parts from the intervals
B<p1, p2, ... pn>.

Example:

  $got = $mcr->partam(4, 2, 2); # [2,2]

=head2 partm

  $partitions = $mcr->partm($n, $m);

Generate all partitions of B<n> into B<m> parts.

Example:

  $got = $mcr->partm(4, 2); # [1,3],[2,2]

=head2 permi

  $permutations = $mcr->permi(\@parts);

Return all permutations of the given B<parts> list as an
array-reference of array-references.

(For an efficient iterator, check out the L<Algorithm::Combinatorics>
module.)

Example:

  my $parts = [qw(1 0 1)];
  my $got = $mcr->permi($parts);
  # [1,0,1],[1,1,0],[0,1,1],[0,1,1],[1,1,0],[1,0,1]

=head2 pfold

  $sequences = $mcr->pfold($n, $m, $f);

Generate "paper folding" sequences, where B<n> is the number of terms
to calculate, B<m> is the size of the binary representation of the
folding function, and B<f> is the folding function number, which can
range from C<0> to C<2^m - 1>.

To quote the book, "Put a rectangular strip of paper on a flat surface
in front of you, with the long dimension going left to right. Now pick
up the right end of the paper and fold it over onto the left end.
Repeat this process a few times and unfold the paper. [There will be]
a sequence of creases in the paper, some will look like valleys and
some will look like ridges... Let valley creases be symbolized by the
number 1 and ridge creases by the number 0..."

Example:

  # "regular paper folding sequence"
  # "folding in the same direction all the time"
  $got = $mcr->pfold(1, 1, 1); # [1]
  $got = $mcr->pfold(2, 1, 1); # [1,1]
  $got = $mcr->pfold(3, 1, 1); # [1,1,0]

  # but other parameters can generate more interesting rhythms...
  $got = $mcr->pfold(15, 4, 0); # [0,0,1,0,0,1,1,0,0,0,1,1,0,1,1]
  $got = $mcr->pfold(15, 4, 1); # [1,0,0,0,1,1,0,0,1,0,0,1,1,1,0]

=head2 reverse_at

  $sequence = $mcr->reverse_at($n, $parts);

Reverse a section of a B<parts> sequence at B<n>.

Examples:

  $parts = [qw(1 0 1 0 0)];
  $got = $mcr->reverse_at(0, $parts); # [0,0,1,0,1]
  $got = $mcr->reverse_at(1, $parts); # [1,0,0,1,0]
  $got = $mcr->reverse_at(2, $parts); # [1,0,0,0,1]
  $got = $mcr->reverse_at(3, $parts); # [1,0,1,0,0]

=head2 rotate_n

  $sequence = $mcr->rotate_n($n, $parts);

Rotate a necklace of the given B<parts>, B<n> times.

Examples:

  $parts = [qw(1 0 1 0 0)];
  $got = $mcr->rotate_n(0, $parts); # [1,0,1,0,0]
  $got = $mcr->rotate_n(1, $parts); # [0,1,0,1,0]
  $got = $mcr->rotate_n(2, $parts); # [0,0,1,0,1]
  $got = $mcr->rotate_n(3, $parts); # [1,0,0,1,0]
  $got = $mcr->rotate_n(4, $parts); # [0,1,0,0,1]
  $got = $mcr->rotate_n(5, $parts); # [1,0,1,0,0]

=head1 SEE ALSO

L<https://abrazol.com/books/rhythm1/> - "Creating Rhythms", the book.

L<https://ology.github.io/2023/03/02/creating-rhythms-with-perl/> - my write-up.

The F<t/01-methods.t> and F<eg/*> programs included with this distribution.

L<Algorithm::Combinatorics>

L<Data::Munge>

L<Integer::Partition>

L<List::Util>

L<Math::Sequence::DeBruijn>

L<Moo>

L<Music::AtonalUtil>

L<Music::CreatingRhythms::SqrtContinued>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
