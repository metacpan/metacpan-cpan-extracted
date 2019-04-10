use utf8;

package SemanticWeb::Schema::CompoundPriceSpecification;

# ABSTRACT: A compound price specification is one that bundles multiple prices that all apply in combination for different dimensions of consumption

use Moo;

extends qw/ SemanticWeb::Schema::PriceSpecification /;


use MooX::JSON_LD 'CompoundPriceSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has price_component => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'priceComponent',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CompoundPriceSpecification - A compound price specification is one that bundles multiple prices that all apply in combination for different dimensions of consumption

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A compound price specification is one that bundles multiple prices that all
apply in combination for different dimensions of consumption. Use the name
property of the attached unit price specification for indicating the
dimension of a price component (e.g. "electricity" or "final cleaning").

=head1 ATTRIBUTES

=head2 C<price_component>

C<priceComponent>

=for html This property links to all <a class="localLink"
href="http://schema.org/UnitPriceSpecification">UnitPriceSpecification</a>
nodes that apply in parallel for the <a class="localLink"
href="http://schema.org/CompoundPriceSpecification">CompoundPriceSpecificat
ion</a> node.

A price_component should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::UnitPriceSpecification']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::PriceSpecification>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
