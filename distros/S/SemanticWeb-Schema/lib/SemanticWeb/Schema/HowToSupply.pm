use utf8;

package SemanticWeb::Schema::HowToSupply;

# ABSTRACT: A supply consumed when performing the instructions for how to achieve a result.

use Moo;

extends qw/ SemanticWeb::Schema::HowToItem /;


use MooX::JSON_LD 'HowToSupply';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has estimated_cost => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'estimatedCost',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HowToSupply - A supply consumed when performing the instructions for how to achieve a result.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A supply consumed when performing the instructions for how to achieve a
result.

=head1 ATTRIBUTES

=head2 C<estimated_cost>

C<estimatedCost>

The estimated cost of the supply or supplies consumed when performing
instructions.

A estimated_cost should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::HowToItem>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
