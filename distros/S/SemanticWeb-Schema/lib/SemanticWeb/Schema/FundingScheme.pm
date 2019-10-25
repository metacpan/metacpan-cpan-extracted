use utf8;

package SemanticWeb::Schema::FundingScheme;

# ABSTRACT: A FundingScheme combines organizational

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'FundingScheme';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v4.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::FundingScheme - A FundingScheme combines organizational

=head1 VERSION

version v4.0.1

=head1 DESCRIPTION

=for html <p>A FundingScheme combines organizational, project and policy aspects of
grant-based funding that sets guidelines, principles and mechanisms to
support other kinds of projects and activities. Funding is typically
organized via <a class="localLink" href="http://schema.org/Grant">Grant</a>
funding. Examples of funding schemes: Swiss Priority Programmes (SPPs); EU
Framework 7 (FP7); Horizon 2020; the NIH-R01 Grant Program; Wellcome
institutional strategic support fund. For large scale public sector
funding, the management and administration of grant awards is often handled
by other, dedicated, organizations - <a class="localLink"
href="http://schema.org/FundingAgency">FundingAgency</a>s such as ERC, REA,
...<p>

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

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
