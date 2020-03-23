use utf8;

package SemanticWeb::Schema::CompoundPriceSpecification;

# ABSTRACT: A compound price specification is one that bundles multiple prices that all apply in combination for different dimensions of consumption

use Moo;

extends qw/ SemanticWeb::Schema::PriceSpecification /;


use MooX::JSON_LD 'CompoundPriceSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.0';


has price_component => (
    is        => 'rw',
    predicate => '_has_price_component',
    json_ld   => 'priceComponent',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CompoundPriceSpecification - A compound price specification is one that bundles multiple prices that all apply in combination for different dimensions of consumption

=head1 VERSION

version v7.0.0

=head1 DESCRIPTION

A compound price specification is one that bundles multiple prices that all
apply in combination for different dimensions of consumption. Use the name
property of the attached unit price specification for indicating the
dimension of a price component (e.g. "electricity" or "final cleaning").

=head1 ATTRIBUTES

=head2 C<price_component>

C<priceComponent>

=for html <p>This property links to all <a class="localLink"
href="http://schema.org/UnitPriceSpecification">UnitPriceSpecification</a>
nodes that apply in parallel for the <a class="localLink"
href="http://schema.org/CompoundPriceSpecification">CompoundPriceSpecificat
ion</a> node.<p>

A price_component should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::UnitPriceSpecification']>

=back

=head2 C<_has_price_component>

A predicate for the L</price_component> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::PriceSpecification>

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
