package Perl::Tags::Hybrid;

use strict; use warnings;
use parent 'Perl::Tags';

our $VERSION = '0.32';

=head1 C<Perl::Tags::Hybrid>

Combine the results of multiple parsers, for example C<Perl::Tags::Naive>
and C<Perl::Tags::PPI>.

=head1 SYNOPSIS

    my $parser = Perl::Tags::Hybrid->new(
        taggers => [
            Perl::Tags::Naive->new,
            Perl::Tags::PPI->new,
        ],
    );

=head2 C<get_tags_for_file>

Registers the results from running each sub-taggers

=cut

sub get_taggers {
    my $self = shift;
    return @{ $self->{taggers} || [] };
}

sub get_tags_for_file {
    my ($self, $file) = @_;

    my @taggers = $self->get_taggers;

    return map { $_->get_tags_for_file( $file ) } @taggers;
}

1;
