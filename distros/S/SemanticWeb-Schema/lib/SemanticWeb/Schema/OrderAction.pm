use utf8;

package SemanticWeb::Schema::OrderAction;

# ABSTRACT: An agent orders an object/product/service to be delivered/sent.

use Moo;

extends qw/ SemanticWeb::Schema::TradeAction /;


use MooX::JSON_LD 'OrderAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has delivery_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'deliveryMethod',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::OrderAction - An agent orders an object/product/service to be delivered/sent.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

An agent orders an object/product/service to be delivered/sent.

=head1 ATTRIBUTES

=head2 C<delivery_method>

C<deliveryMethod>

A sub property of instrument. The method of delivery.

A delivery_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryMethod']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::TradeAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
