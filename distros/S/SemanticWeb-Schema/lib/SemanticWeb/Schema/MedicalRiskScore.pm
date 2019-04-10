use utf8;

package SemanticWeb::Schema::MedicalRiskScore;

# ABSTRACT: A simple system that adds up the number of risk factors to yield a score that is associated with prognosis

use Moo;

extends qw/ SemanticWeb::Schema::MedicalRiskEstimator /;


use MooX::JSON_LD 'MedicalRiskScore';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


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

version v3.5.0

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

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
