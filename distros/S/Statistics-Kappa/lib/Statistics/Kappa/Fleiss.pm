package Statistics::Kappa::Fleiss;
use 5.026;

our $VERSION = '0.02';

use Moo;
use experimental qw{ signatures };

use List::Util qw{ sum };
use namespace::clean;

has data           => (is => 'ro',   required => 1);
has kappa          => (is => 'lazy', init_arg => undef);
has proportion     => (is => 'lazy', init_arg => undef);
has extent         => (is => 'lazy', init_arg => undef);
has category_count => (is => 'lazy', init_arg => undef);
has mean           => (is => 'lazy', init_arg => undef);
has pe             => (is => 'lazy', init_arg => undef);


sub _build_category_count($self) {
    sum(@{ $self->data->[0] })
}

sub _build_proportion($self) {
    my %p;
    for my $j (0 .. $#{ $self->data->[0] }) {
        $p{$j} = sum(map $self->data->[$_][$j], 0 .. $#{ $self->data })
               / (@{ $self->data } * $self->category_count);
    }
    return \%p
}

sub _build_extent($self) {
    my %p;
    $p{$_} = (sum(map $_ ** 2, @{ $self->data->[$_] }) - $self->category_count)
           / $self->category_count / ($self->category_count - 1)
           for 0 .. $#{ $self->data };
    return \%p
}

sub _build_mean($self) {
    sum(values %{ $self->extent }) / @{ $self->data }
}

sub _build_pe($self) {
    sum(map $_ ** 2, values %{ $self->proportion })
}

sub _build_kappa($self) {
    ($self->mean - $self->pe) / (1 - $self->pe)
}




=head1 NAME

Statistics::Kappa::Fleiss - Calculate inter-annotator agreement.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Statistics::Kappa::Fleiss;

    my @data = ([0, 0, 0, 0, 14],
                [0, 2, 6, 4, 2],
                [0, 0, 3, 5, 6]);
    my $fk = 'Statistics::Kappa::Fleiss'->new(data => \@data);
    my $kappa = $fk->kappa;

=head1 METHODS

=head2 'Statistics::Kappa::Fleiss'->new(data => \@data)

The constructor. It takes a named argument C<data> which should contain an
array reference. Each element of the array represents a rated item by another
anonymous array, which on position C<j> contains the number of raters that
assigned the category C<j> to the item. Therefore, the format of the data is
I<different> to other L<Statistics::Kappa> modules.

=head2 data

=head1 AUTHOR

E. Choroba <choroba@matfyz.cz>

=head1 BUGS

Please report any bugs or feature requests to the L<GitHub
repository|https://github.com/choroba/statistics-kappa>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Kappa::Fleiss

You can also look for information at:

=over 4

=item * GitHub issue tracker (report bugs here)

L<https://github.com/choroba/Statistics-Kappa/issues>

=item * Search CPAN

L<https://metacpan.org/release/Statistics-Kappa>

=back

=head1 SEE ALSO

Other modules from L<Statistics::Kappa>: L<Statistics::Kappa::Cohen> and
L<Statistics::Kappa::Weighted>. Another inter-rater agreement statistics:
L<Statistics::Krippendorff>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by E. Choroba <choroba@matfyz.cz>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__PACKAGE__
