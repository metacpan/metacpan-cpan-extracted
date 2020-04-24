use utf8;

package SemanticWeb::Schema::FundingAgency;

# ABSTRACT: A FundingAgency is an organization that implements one or more FundingScheme s and manages the granting process (via Grant s

use Moo;

extends qw/ SemanticWeb::Schema::Project /;


use MooX::JSON_LD 'FundingAgency';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::FundingAgency - A FundingAgency is an organization that implements one or more FundingScheme s and manages the granting process (via Grant s

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

=for html <p>A FundingAgency is an organization that implements one or more <a
class="localLink" href="http://schema.org/FundingScheme">FundingScheme</a>s
and manages the granting process (via <a class="localLink"
href="http://schema.org/Grant">Grant</a>s, typically <a class="localLink"
href="http://schema.org/MonetaryGrant">MonetaryGrant</a>s). A funding
agency is not always required for grant funding, e.g. philanthropic giving,
corporate sponsorship etc.<br/><br/> <pre><code>Examples of funding
agencies include ERC, REA, NIH, Bill and Melinda Gates Foundation...
</code></pre> <p>

=head1 SEE ALSO

L<SemanticWeb::Schema::Project>

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
