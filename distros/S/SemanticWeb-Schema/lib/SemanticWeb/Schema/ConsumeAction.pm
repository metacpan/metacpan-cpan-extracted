package SemanticWeb::Schema::ConsumeAction;

# ABSTRACT: The act of ingesting information/resources/food.

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'ConsumeAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has expects_acceptance_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'expectsAcceptanceOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ConsumeAction - The act of ingesting information/resources/food.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

The act of ingesting information/resources/food.

=head1 ATTRIBUTES

=head2 C<expects_acceptance_of>

C<expectsAcceptanceOf>

An Offer which must be accepted before the user can perform the Action. For
example, the user may need to buy a movie before being able to watch it.

A expects_acceptance_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Action>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
