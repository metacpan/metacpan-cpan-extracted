use utf8;

package SemanticWeb::Schema::BuyAction;

# ABSTRACT: The act of giving money to a seller in exchange for goods or services rendered

use Moo;

extends qw/ SemanticWeb::Schema::TradeAction /;


use MooX::JSON_LD 'BuyAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has seller => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seller',
);



has vendor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vendor',
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

SemanticWeb::Schema::BuyAction - The act of giving money to a seller in exchange for goods or services rendered

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

The act of giving money to a seller in exchange for goods or services
rendered. An agent buys an object, product, or service from a seller for a
price. Reciprocal of SellAction.

=head1 ATTRIBUTES

=head2 C<seller>

An entity which offers (sells / leases / lends / loans) the services /
goods. A seller may also be a provider.

A seller should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<vendor>

'vendor' is an earlier term for 'seller'.

A vendor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

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
