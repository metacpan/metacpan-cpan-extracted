use utf8;

package SemanticWeb::Schema::MonetaryGrant;

# ABSTRACT: A monetary grant.

use Moo;

extends qw/ SemanticWeb::Schema::Grant /;


use MooX::JSON_LD 'MonetaryGrant';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has amount => (
    is        => 'rw',
    predicate => '_has_amount',
    json_ld   => 'amount',
);



has funder => (
    is        => 'rw',
    predicate => '_has_funder',
    json_ld   => 'funder',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MonetaryGrant - A monetary grant.

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

A monetary grant.

=head1 ATTRIBUTES

=head2 C<amount>

The amount of money.

A amount should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<Num>

=back

=head2 C<_has_amount>

A predicate for the L</amount> attribute.

=head2 C<funder>

A person or organization that supports (sponsors) something through some
kind of financial contribution.

A funder should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_funder>

A predicate for the L</funder> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Grant>

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
