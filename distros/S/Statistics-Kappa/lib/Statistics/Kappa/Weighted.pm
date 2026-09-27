package Statistics::Kappa::Weighted;
use 5.026;

our $VERSION = '0.03';

use Moo;
use experimental qw{ signatures };

use List::Util qw{ sum };
use namespace::clean;

has data        => (is => 'ro',   required => 1);
has weight      => (is => 'ro',   required => 1);
has kappa       => (is => 'lazy', init_arg => undef);
has categories  => (is => 'lazy', init_arg => undef);
has coincidence => (is => 'lazy', init_arg => undef);
has expected    => (is => 'lazy', init_arg => undef);
has _weight     => (is => 'lazy', init_arg => undef);


sub _build_kappa($self) {
    1 - sum(map { my $c1 = $_;
                  map +($self->coincidence->{$c1}{$_} // 0)
                      * $self->_weight->($c1, $_),
                  @{ $self->categories }
            } @{ $self->categories })
        / sum(map { my $c1 = $_;
                    map $self->expected->{$c1}{$_} * $self->_weight->($c1, $_),
                    @{ $self->categories }
              } @{ $self->categories })
}


sub _build_categories($self) {
    my %c;
    @c{ map @$_, @{ $self->{data} } } = ();
    return [sort keys %c]
}


sub _build_coincidence($self) {
    my %ci;
    ++$ci{ $_->[0] }{ $_->[1] } for @{ $self->data };
    return \%ci
}


sub _build_expected($self) {
    my $ci = $self->coincidence;
    my @cat = @{ $self->categories };
    my %r;
    $r{$_} = sum(values %{ $ci->{$_} }) / @{ $self->data } for @cat;
    my %c;
    for my $cat (@cat) {
        $c{$cat} = sum(map $_->{$cat} // 0, values %$ci) / @{ $self->data };
    }

    my %e;
    for my $c1 (@cat) {
        for my $c2 (@cat) {
            $e{$c1}{$c2} = $r{$c1} * $c{$c2} * @{ $self->data };
        }
    }
    return \%e
}


{   my %WEIGHT = (linear    => sub { abs($_[0] - $_[1]) },
                  quadratic => sub { ($_[0] - $_[1]) ** 2 });

    sub _build__weight($self) {
        return $self->weight if ref sub {} eq ref $self->weight;
        return $WEIGHT{ $self->weight } if exists $WEIGHT{ $self->weight };
        die 'Unknown weight ' . $self->weight
    }
}

=encoding utf8

=head1 NAME

Statistics::Kappa::Weighted - Calculate inter-annotator agreement.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Statistics::Kappa::Weighted;

    sub weight($x, $y) { abs($x - $y) }

    my @data = ([3, 2], [2, 2], [1, 1], [2, 2], [3, 3]);
    my $ck = 'Statistics::Kappa::Weighted'->new(data   => \@data,
                                                weight => \&weight);
    my $kappa =  $ck->kappa;

=head1 METHODS

=head2 'Statistics::Kappa::Weighted'->new(data => \@data, weight => \&weight)

The constructor. It takes a named argument C<data> which should contain an
array reference. The elements of the array should be anonymous arrays of two
elements, representing answers by the two raters we are comparing. Another
argument is C<weight> which should be a code reference returning the weight of
disagreement (0 if the two values are the same). Two values of C<weight> are
predefined: strings C<'linear'> and C<'quadratic'>. You can use them if the
values are numbers and the weight is C<abs($x - $y)> or C<($x - $y) ** 2>,
respectively. Note that using C<sub { $_[0] != $_[1] }> turns the weighted
𝜅 into unweighted 𝜅.

=head2 data

=head2 weight

=head1 AUTHOR

E. Choroba <choroba@matfyz.cz>

=head1 BUGS

Please report any bugs or feature requests to the L<GitHub
repository|https://github.com/choroba/statistics-kappa>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Kappa::Weighted

You can also look for information at:

=over 4

=item * GitHub issue tracker (report bugs here)

L<https://github.com/choroba/statistics-kappa/issues>

=item * Search CPAN

L<https://metacpan.org/release/Statistics-Kappa>

=back

=head1 SEE ALSO

Other modules from L<Statistics::Kappa>: L<Statistics::Kappa::Cohen> and
L<Statistics::Kappa::Fleiss>. Another inter-rater agreement statistics:
L<Statistics::Krippendorff>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by E. Choroba <choroba@matfyz.cz>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__PACKAGE__
