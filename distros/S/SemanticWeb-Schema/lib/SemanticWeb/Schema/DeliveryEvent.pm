use utf8;

package SemanticWeb::Schema::DeliveryEvent;

# ABSTRACT: An event involving the delivery of an item.

use Moo;

extends qw/ SemanticWeb::Schema::Event /;


use MooX::JSON_LD 'DeliveryEvent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has access_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'accessCode',
);



has available_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availableFrom',
);



has available_through => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availableThrough',
);



has has_delivery_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasDeliveryMethod',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DeliveryEvent - An event involving the delivery of an item.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

An event involving the delivery of an item.

=head1 ATTRIBUTES

=head2 C<access_code>

C<accessCode>

Password, PIN, or access code needed for delivery (e.g. from a locker).

A access_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<available_from>

C<availableFrom>

When the item is available for pickup from the store, locker, etc.

A available_from should be one of the following types:

=over

=item C<Str>

=back

=head2 C<available_through>

C<availableThrough>

After this date, the item will no longer be available for pickup.

A available_through should be one of the following types:

=over

=item C<Str>

=back

=head2 C<has_delivery_method>

C<hasDeliveryMethod>

Method used for delivery or shipping.

A has_delivery_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryMethod']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Event>

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
