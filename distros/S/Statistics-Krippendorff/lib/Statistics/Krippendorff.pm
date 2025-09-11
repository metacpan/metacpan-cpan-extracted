=head1 NAME

Statistics::Krippendorff - Calculate Krippendorff's alpha

=head1 VERSION

Version 0.04

=cut

package Statistics::Krippendorff;

use 5.026;

use Moo;

use experimental qw( signatures );

our $VERSION = '0.04';

use List::Util qw{ min sum };

use namespace::clean;

has units       => (is       => 'ro',
                    required => 1,
                    coerce   => \&_units_array2hash);

has delta       => (is      => 'rw',
                    default => sub { \&delta_nominal },
                    trigger => sub ($self, $d) {
                        $self->delta($self->_deltas->{$d})
                            if exists $self->_deltas->{$d};
                    });

has coincidence => (is => 'lazy', init_arg => undef);

has _vals       => (is       => 'lazy',
                    init_arg => undef,
                    builder  => '_build_vals');

has _frequency  => (is => 'lazy',
                    init_arg => undef,
                    builder => '_build_frequency');

has _expected   => (is => 'lazy',
                    init_arg => undef,
                    builder => '_build_expected');

has _deltas     => (is => 'ro',
                    init_arg => undef,
                    default => sub { +{
                        nominal  => \&delta_nominal,
                        interval => \&delta_interval,
                        ordinal  => \&delta_ordinal,
                        ratio    => \&delta_ratio,
                        jaccard  => \&delta_jaccard,
                        masi     => \&delta_masi
                    } });

sub alpha($self) {
    my $d_o = sum(map {
        my $v = $_;
        map {
            $self->coincidence->{$v}{$_} * $self->delta->($self, $v, $_)
        } $self->vals
    } $self->vals);
    my $d_e = sum(map {
        my $v = $_;
        map {
            $self->_expected->{$v}{$_} * $self->delta->($self, $v, $_)
        } $self->vals
    } $self->vals);
    my $alpha = 1 - $d_o / $d_e;
    return $alpha
}

sub vals($self) { @{ $self->_vals } }

sub frequency($self, $value) {
    return $self->_frequency->{$value}
}

sub pairable_values($self) {
    return sum(values %{ $self->_frequency })
}

sub is_valid($self) {
    for my $unit (@{ $self->units }) {
        return if 1 >= keys %$unit;
        return if grep ! defined, values %$unit;
    }
    return 1
}

sub delta_nominal($, $s1, $s2) { $s1 eq $s2 ? 0 : 1 }

sub delta_interval($, $v0, $v1) { ($v0 - $v1) ** 2 }

sub delta_ordinal($self, $v0, $v1) {
    my ($from, $to) = sort { $a <=> $b } $v0, $v1;
    (sum(map $self->frequency($_), $from .. $to)
     - ($self->frequency($from) + $self->frequency($to))/ 2) ** 2
}

sub delta_ratio($, $v0, $v1) { (($v0 - $v1) / ($v0 + $v1)) ** 2}

sub delta_jaccard($, $s1, $s2) {
    my @s1 = split /,/, $s1;
    my @s2 = split /,/, $s2;

    my %union;
    @union{ @s1, @s2 } = ();

    my %intersection;
    @intersection{@s1} = ();

    return 1 - (grep exists $intersection{$_}, @s2) / keys %union
}

sub delta_masi($, $v0, $v1) {
        my @v0 = split /,/, $v0;
        my @v1 = split /,/, $v1;
        my %union;
        @union{ @v0, @v1 } = ();
        my $union = keys %union;

        my %intersection;
        @intersection{ @v0 } = ();
        my $intersection = grep exists $intersection{$_}, @v1;

        # Python's nltk uses 0.67 and 0.33 which gives a different result for
        # precission 4.
        my $m = (@v0 == @v1 && @v0 == $intersection)         ? 1
              : $intersection == min(scalar @v0, scalar @v1) ? 2 / 3
              : $intersection > 0                            ? 1 / 3
              :                                                0;
        return 1 - $intersection / $union * $m
}

sub _units_array2hash($units) {
    if (ref [] eq ref $units->[0]) {
        return [map {
            my $unit = $_;
            +{map +($_ => $unit->[$_]),
              grep defined $unit->[$_],
              0 .. $#$unit}
        } @$units]
    }
    return $units
}

sub _build_vals($self) {
    my %subf;
    @subf{ map values %$_, @{ $self->units } } = ();
    return [sort keys %subf]
}

sub _build_coincidence($self) {
    my @vals = $self->vals;
    my %coinc;
    @{ $coinc{$_} }{@vals} = (0) x @vals for @vals;

    for my $unit (@{ $self->units }) {
        my %is_value;
        @is_value{ values %$unit } = ();
        my @values = keys %is_value;
        my @keys   = keys %$unit;

        for my $v (@values) {
            for my $v_ (@values) {
                my $coinc_count = 0;
                for my $key1 (@keys) {
                    for my $key2 (@keys) {
                        next if $key1 eq $key2;

                        ++$coinc_count
                            if $unit->{$key1} eq $v
                            && $unit->{$key2} eq $v_;
                    }
                }
                $coinc{$v}{$v_} += $coinc_count / (@keys - 1);
            }
        }
    }
    return \%coinc
}

sub _build_frequency($self) {
    my %f;
    @f{ $self->vals } = map sum(values %{ $self->coincidence->{$_} }),
                              $self->vals;
    return \%f
}

sub _build_expected($self) {
    my %exp;
    my $n = $self->pairable_values - 1;
    for my $v ($self->vals) {
        for my $v_ ($self->vals) {
            $exp{$v}{$v_} = ($v eq $v_
                             ? $self->frequency($v) * ($self->frequency($v) - 1)
                             : $self->frequency($v) * $self->frequency($v_)
                            ) / $n;
        }
    }
    return \%exp
}

=head1 SYNOPSIS

  use experimental qw( signatures );
  use Statistics::Krippendorff ();

  my @units = ({coder1 => 1, coder2 => 1},
               {coder1 => 2, coder2 => 2, coder3 => 1},
               {coder2 => 3, coder3 => 2});
  my $sk = 'Statistics::Krippendorff'->new(units => \@units);
  my $alpha1 = $sk->alpha;
  $sk->delta('nominal');  # Same as default.
  my $alpha2 = $sk->alpha;

  my $ski = 'Statistics::Krippendorff'->new(
                units => [[1, 1], [2,2,1], [undef,3,2]],
                delta => sub ($, $v0, $v1) { ($v0 - $v1) ** 2 });
  my $alpha_interval = $ski->alpha;

=head1 METHODS

=head2 new

  my $sk = 'Statistics::Krippendorff'->new(
               units => \@units,
               delta => 'nominal');

The constructor. It accepts the following named arguments:

=head3 units

An array reference of units. All units of analysis must be of the same type,
but there are two possible types they all can have:

=over

=item 1.

Each unit is a hash reference of the form

  { coder1 => 'value1', coder3 => 'value2', ... }

=item 2.

Each unit is an array reference of the form

  ['value1', undef, 'value2']

where the coder is encoded by the position in the array, missing data are
indicated by an C<undef>.


=back

In both the cases, there must be at least two values in each unit. If you want
to validate this precondition, call C<is_valid>.

=head3 delta

An optional argument defaulting to delta_nominal. You can specify any function
C<f($self, $v1, $v2)> that compares the two values C<$v1> and C<$v2> and
returns their distance (a number between 0 and 1). Several common methods are
predefined, you can use a code reference like C<&Statistics::Krippendorff::delta_nominal> or just a string C<nominal>:

=head4 delta_nominal

Used for nominal data, i.e. labels with no ordering.

=head4 delta_ordinal

Used for numeric values that are ordered, but can't be used in mathematical
operations, for example number of stars in a movie rating system (we don't say
that the distance from one star to two stars is the same as the distance from
three starts to four stars). See the implementation on why C<$self> is needed
as a parameter to delta.

=head4 delta_interval

Used for numeric values that can be used in mathematical operations.

=head4 delta_ratio

Used for non-negative numeric values (think degrees Kelvin).

=head4 delta_jaccard

This can be used when coders can specify more than one value. Join the values
with commas; Jaccard index then uses the formula C<intersection_size /
union_size>. If you sort the values before joining them, the expected
coincidence matrix is smaller and the algorithm runs faster, but the resulting
coefficient should be the same.

=head4 delta_masi

The weighted metric for measuring agreement on set-valued items introduced by
R. Passonneau (2006). Use comma separated values as above in C<delta_jaccard>.
Note that the Python implementation in L<nltk|https://www.nltk.org> uses the
weights rounded with precision 2, so the resutls might be slightly different.

=head2 alpha

  my $alpha = $sk->alpha;

Returns Krippendorff's alpha.

=head2 delta

  $sk->delta(sub($self, $v1, $v2) {});
  $sk->delta('jaccard');

The difference function used to calculate the alpha. You can specify it in the
constructor (see above), but you can later change it so something else, too.

=head2 is_valid

  print "OK" if $sk->is_valid;

Check that each unit has at least two responses. If you use a hash
representation of a unit, the values must be always defined.

=head2 frequency

  my $freq = $sk->frequency('val1');

Returns the frequency of the given value.

=head2 pairable_values

Returns the total number of all pairable values (i.e. the sum of all
frequencies).

=head2 vals

Returns a sorted list of all the possible values.

=head1 AUTHOR

E. Choroba, C<< <choroba at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/choroba/statistics-krippendorff/issues>, via
e-mail to C<bug-statistics-krippendorff at rt.cpan.org>, or through
the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Krippendorff>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Krippendorff


You can also look for information at:

=over 4

=item * GitHub (report bugs here)

L<https://github.com/choroba/statistics-krippendorff>

=item * Search CPAN

L<https://metacpan.org/release/Statistics-Krippendorff>

=item * RT: CPAN's request tracker (you can report bugs here, too)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Krippendorff>

=back


=head1 ACKNOWLEDGEMENTS

Implementation inspired by
L<Wikipedia|https://en.wikipedia.org/wiki/Krippendorff%27s_alpha>,
additional tests taken from
L<https://www.infoamerica.org/documentos_pdf/kripen.pdf>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by E. Choroba.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

__PACKAGE__
