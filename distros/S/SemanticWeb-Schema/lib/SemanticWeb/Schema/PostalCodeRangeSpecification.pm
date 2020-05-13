use utf8;

package SemanticWeb::Schema::PostalCodeRangeSpecification;

# ABSTRACT: Indicates a range of postalcodes

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'PostalCodeRangeSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has postal_code_begin => (
    is        => 'rw',
    predicate => '_has_postal_code_begin',
    json_ld   => 'postalCodeBegin',
);



has postal_code_end => (
    is        => 'rw',
    predicate => '_has_postal_code_end',
    json_ld   => 'postalCodeEnd',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PostalCodeRangeSpecification - Indicates a range of postalcodes

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

=for html <p>Indicates a range of postalcodes, usually defined as the set of valid
codes between <a class="localLink"
href="http://schema.org/postalCodeBegin">postalCodeBegin</a> and <a
class="localLink" href="http://schema.org/postalCodeEnd">postalCodeEnd</a>,
inclusively.<p>

=head1 ATTRIBUTES

=head2 C<postal_code_begin>

C<postalCodeBegin>

First postal code in a range (included).

A postal_code_begin should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_postal_code_begin>

A predicate for the L</postal_code_begin> attribute.

=head2 C<postal_code_end>

C<postalCodeEnd>

=for html <p>Last postal code in the range (included). Needs to be after <a
class="localLink"
href="http://schema.org/postalCodeBegin">postalCodeBegin</a>.<p>

A postal_code_end should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_postal_code_end>

A predicate for the L</postal_code_end> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::StructuredValue>

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
