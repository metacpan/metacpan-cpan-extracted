package Peta::Vorbis::Encode::Book;
# ABSTRACT: a Vorbis codebook

# A Vorbis codebook: entries, each with a codeword, and for the residue's
# books a vector of values per entry (a lattice: lookup type 1).
#
# The codeword lengths come from weights (how often an entry is expected)
# by Huffman's construction; the codewords themselves are assigned as the
# Vorbis I specification defines them: entry after entry, each the lowest
# valued codeword of its length that is still free (the leftmost free
# place of that depth in the code tree). A complete tree is checked: the
# lengths must fill it exactly.
#
# A lattice book of dimension d over m values (value j being minimum + j *
# delta) has m^d entries; entry e's value i is value number (e / m^i) % m.

use v5.36;
use List::Util qw(max);

our $VERSION = '0.2610180';

use constant SYNC => 0x564342;

# new(dimensions => d, values => m, delta => ..., minimum => ..., weights => \@w)
# for a lattice book; new(entries => n, weights => \@w) for a scalar book
# (no values: floors and classifications).
sub new ($class, %arg) {
    my $dim     = $arg{dimensions} // 1;
    my $m       = $arg{values};
    my $entries = $m ? $m**$dim : $arg{entries};
    my $w       = $arg{weights} // [ (1) x $entries ];
    die "weights for $entries entries, not " . @$w . "\n" if @$w != $entries;

    my $lengths = _lengths($w);
    return bless {
        dim     => $dim,
        m       => $m,
        entries => $entries,
        delta   => $arg{delta},
        minimum => $arg{minimum},
        lengths => $lengths,
        codes   => _codes($lengths),
    }, $class;
}

sub entries ($self)    { return $self->{entries} }
sub dimensions ($self) { return $self->{dim} }
sub lengths ($self)    { return $self->{lengths} }

# The codeword lengths of a Huffman code for the weights, none longer than
# 32 bits (Vorbis' limit): weights too small to matter are raised.
sub _lengths ($w) {
    my $n = @$w;
    return [1] if $n == 1;    # a single entry: one bit (Vorbis I errata)

    my $total = 0;
    $total += $_ for @$w;

    for my $floor (1e-9, 1e-7, 1e-5, 1e-3) {
        my $least = $floor * $total;

        # Merge the two lightest trees, until one is left; each entry's
        # depth is how often its tree was merged.
        my @depth   = (0) x $n;
        my @members = map { [$_] } 0 .. $n - 1;
        my @heap    = map { [ ($w->[$_] > $least ? $w->[$_] : $least), $_ ] } 0 .. $n - 1;
        while (@heap > 1) {
            @heap = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @heap;
            my ($x, $y) = splice @heap, 0, 2;
            my @both = (@{ $members[ $x->[1] ] }, @{ $members[ $y->[1] ] });
            $depth[$_]++ for @both;
            $members[ $x->[1] ] = \@both;
            push @heap, [ $x->[0] + $y->[0], $x->[1] ];
        }
        return \@depth if max(@depth) <= 32;
    }
    die "no Huffman code within 32 bits\n";
}

# The codewords, as the specification assigns them: [ value, length ] per
# entry, the value's bits read from the most significant.
sub _codes ($lengths) {
    my $root = {};
    my @codes;
    for my $e (0 .. $#$lengths) {
        my $length = $lengths->[$e];
        my $code = _take($root, $length, 0);
        die "codebook lengths overfill the code tree (entry $e)\n" if !defined $code;
        push @codes, [ $code, $length ];
    }
    die "codebook lengths leave the code tree unfilled\n" if @$lengths > 1 && !$root->{full};
    return \@codes;
}

# The leftmost free place at $depth below $node: its value, or undef.
sub _take ($node, $depth, $value) {
    return undef if $node->{full} || $node->{leaf};
    if ($depth == 0) {
        return undef if $node->{0} || $node->{1};    # an inner node: taken below
        $node->{leaf} = $node->{full} = 1;
        return $value;
    }
    for my $bit (0, 1) {
        my $child = $node->{$bit} //= {};
        my $got = _take($child, $depth - 1, 2 * $value + $bit);
        if (defined $got) {
            $node->{full} = 1 if $node->{0} && $node->{0}{full} && $node->{1} && $node->{1}{full};
            return $got;
        }
    }
    return undef;
}

# The values of an entry of a lattice book.
sub vector ($self, $entry) {
    my @v;
    my $div = 1;
    for (1 .. $self->{dim}) {
        push @v, $self->{minimum} + (int($entry / $div) % $self->{m}) * $self->{delta};
        $div *= $self->{m};
    }
    return @v;
}

# The entry of a lattice book whose values are these (each one of the
# book's values): value i is the entry's digit i, in base m.
sub entry ($self, @values) {
    my ($entry, $mul) = (0, 1);
    for my $v (@values) {
        $entry += $mul * int(($v - $self->{minimum}) / $self->{delta} + 0.5);
        $mul *= $self->{m};
    }
    return $entry;
}

# Writes an entry's codeword: its bits from the most significant, into a
# writer that packs from the least significant (so the code goes reversed).
sub put ($self, $out, $entry) {
    $self->{counts}[$entry]++ if $self->{counts};
    my ($code, $length) = @{ $self->{codes}[$entry] };
    my $reversed = 0;
    for (1 .. $length) {
        $reversed = ($reversed << 1) | ($code & 1);
        $code >>= 1;
    }
    $out->put($reversed, $length);
    return;
}

# Counting the entries written from now on (for training the weights):
# the counts so far.
sub count ($self) { return $self->{counts} //= [ (0) x $self->{entries} ] }

# The bits of an entry's codeword.
sub bits ($self, $entry) { return $self->{lengths}[$entry] }

# The book in the setup header.
sub header ($self, $out) {
    $out->put(SYNC, 24);
    $out->put($self->{dim}, 16);
    $out->put($self->{entries}, 24);
    $out->put(0, 1);    # not ordered
    $out->put(0, 1);    # not sparse: every entry has a codeword
    $out->put($_ - 1, 5) for @{ $self->{lengths} };

    if (!$self->{m}) {
        $out->put(0, 4);    # lookup type 0: no values
        return;
    }

    $out->put(1, 4);    # lookup type 1: a lattice
    $out->put(float32($self->{minimum}), 32);
    $out->put(float32($self->{delta}), 32);
    my $bits = 1;
    $bits++ while (1 << $bits) < $self->{m};
    $out->put($bits - 1, 4);
    $out->put(0, 1);    # values not cumulative
    $out->put($_, $bits) for 0 .. $self->{m} - 1;
    return;
}

# Vorbis' float32: a sign, a 10-bit exponent and a 21-bit mantissa, read as
# mantissa * 2^(exponent - 788). Here the mantissa holds x * 2^(20 - e), so
# the exponent stored is e + 768.
sub float32 ($x) {
    return 0 if $x == 0;
    my $sign = $x < 0 ? 0x80000000 : 0;
    $x = abs $x;
    my $exp = int(log($x) / log(2));
    $exp-- while 2**$exp > $x;
    $exp++ while 2**($exp + 1) <= $x;
    my $mantissa = int($x * 2**(20 - $exp) + 0.5);
    if ($mantissa >= 1 << 21) { $mantissa >>= 1; $exp++ }
    return $sign | (($exp + 768) << 21) | $mantissa;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Vorbis::Encode::Book - a Vorbis codebook

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $book = Peta::Vorbis::Encode::Book->new(dimensions => 2, values => 5,
        minimum => -2, delta => 1, weights => \@weights);
    $book->header($writer);                        # in the setup header
    $book->put($writer, $book->entry(-1, 2));      # a vector, coded

=head1 DESCRIPTION

Huffman code lengths from weights, codewords as Vorbis I assigns them,
lattice values (lookup type 1), and the book's form in the setup header.

=head1 METHODS

=head2 new

C<< new(dimensions => d, values => m, delta => ..., minimum => ...,
weights => \@w) >>: a lattice book; C<< new(entries => n, weights => \@w) >>:
a scalar one (floors and classifications).

=head2 entries, dimensions, lengths

How many entries it has, how many values each, their code lengths.

=head2 vector, entry

C<vector($entry)>: a lattice book's values of an entry;
C<entry(@values)>: the entry of those values (value i its digit i, in
base m).

=head2 put, bits

C<put($out, $entry)>: an entry's codeword into a bit writer;
C<bits($entry)>: its length.

=head2 count

Counting the entries written from now on (for training the weights): the
counts so far.

=head2 header

C<header($out)>: the book in the setup header.

=head1 FUNCTIONS

=head2 float32

C<float32($x)>: Vorbis' float32 of a number (sign, 10-bit exponent,
21-bit mantissa).

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
