use utf8;

package SemanticWeb::Schema::HowToItem;

# ABSTRACT: An item used as either a tool or supply when performing the instructions for how to to achieve a result.

use Moo;

extends qw/ SemanticWeb::Schema::ListItem /;


use MooX::JSON_LD 'HowToItem';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has required_quantity => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'requiredQuantity',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HowToItem - An item used as either a tool or supply when performing the instructions for how to to achieve a result.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

An item used as either a tool or supply when performing the instructions
for how to to achieve a result.

=head1 ATTRIBUTES

=head2 C<required_quantity>

C<requiredQuantity>

The required quantity of the item(s).

A required_quantity should be one of the following types:

=over

=item C<Str>

=item C<Num>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::ListItem>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
