use utf8;

package SemanticWeb::Schema::MedicalRiskScore;

# ABSTRACT: A simple system that adds up the number of risk factors to yield a score that is associated with prognosis

use Moo;

extends qw/ SemanticWeb::Schema::MedicalRiskEstimator /;


use MooX::JSON_LD 'MedicalRiskScore';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has algorithm => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'algorithm',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalRiskScore - A simple system that adds up the number of risk factors to yield a score that is associated with prognosis

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A simple system that adds up the number of risk factors to yield a score
that is associated with prognosis, e.g. CHAD score, TIMI risk score.

=head1 ATTRIBUTES

=head2 C<algorithm>

The algorithm or rules to follow to compute the score.

A algorithm should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalRiskEstimator>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
