use utf8;

package SemanticWeb::Schema::SellAction;

# ABSTRACT: The act of taking money from a buyer in exchange for goods or services rendered

use Moo;

extends qw/ SemanticWeb::Schema::TradeAction /;


use MooX::JSON_LD 'SellAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has buyer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'buyer',
);



has warranty_promise => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'warrantyPromise',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SellAction - The act of taking money from a buyer in exchange for goods or services rendered

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

The act of taking money from a buyer in exchange for goods or services
rendered. An agent sells an object, product, or service to a buyer for a
price. Reciprocal of BuyAction.

=head1 ATTRIBUTES

=head2 C<buyer>

A sub property of participant. The participant/person/organization that
bought the object.

A buyer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<warranty_promise>

C<warrantyPromise>

The warranty promise(s) included in the offer.

A warranty_promise should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WarrantyPromise']>

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
