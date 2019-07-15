use utf8;

package SemanticWeb::Schema::OwnershipInfo;

# ABSTRACT: A structured value providing information about when a certain organization or person owned a certain product.

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'OwnershipInfo';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has acquired_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'acquiredFrom',
);



has owned_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'ownedFrom',
);



has owned_through => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'ownedThrough',
);



has type_of_good => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'typeOfGood',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::OwnershipInfo - A structured value providing information about when a certain organization or person owned a certain product.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A structured value providing information about when a certain organization
or person owned a certain product.

=head1 ATTRIBUTES

=head2 C<acquired_from>

C<acquiredFrom>

The organization or person from which the product was acquired.

A acquired_from should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<owned_from>

C<ownedFrom>

The date and time of obtaining the product.

A owned_from should be one of the following types:

=over

=item C<Str>

=back

=head2 C<owned_through>

C<ownedThrough>

The date and time of giving up ownership on the product.

A owned_through should be one of the following types:

=over

=item C<Str>

=back

=head2 C<type_of_good>

C<typeOfGood>

The product that this structured value is referring to.

A type_of_good should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<InstanceOf['SemanticWeb::Schema::Service']>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
