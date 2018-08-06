package SemanticWeb::Schema::MoveAction;

# ABSTRACT: <p>The act of an agent relocating to a place

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'MoveAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


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

SemanticWeb::Schema::MoveAction - <p>The act of an agent relocating to a place

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>The act of an agent relocating to a place.</p> <p>Related actions:</p>
<ul> <li><a class="localLink"
href="http://schema.org/TransferAction">TransferAction</a>: Unlike
TransferAction, the subject of the move is a living Person or Organization
rather than an inanimate object.</li> </ul> 

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
