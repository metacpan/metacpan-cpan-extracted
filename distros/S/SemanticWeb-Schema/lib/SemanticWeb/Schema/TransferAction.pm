use utf8;

package SemanticWeb::Schema::TransferAction;

# ABSTRACT: The act of transferring/moving (abstract or concrete) animate or inanimate objects from one place to another.

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'TransferAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has from_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'fromLocation',
);



has to_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'toLocation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TransferAction - The act of transferring/moving (abstract or concrete) animate or inanimate objects from one place to another.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

The act of transferring/moving (abstract or concrete) animate or inanimate
objects from one place to another.

=head1 ATTRIBUTES

=head2 C<from_location>

C<fromLocation>

A sub property of location. The original location of the object or the
agent before the action.

A from_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<to_location>

C<toLocation>

A sub property of location. The final location of the object or the agent
after the action.

A to_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

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
