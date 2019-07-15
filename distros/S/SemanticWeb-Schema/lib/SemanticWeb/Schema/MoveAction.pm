use utf8;

package SemanticWeb::Schema::MoveAction;

# ABSTRACT: The act of an agent relocating to a place

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'MoveAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


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

SemanticWeb::Schema::MoveAction - The act of an agent relocating to a place

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html The act of an agent relocating to a place.<br/><br/> Related
actions:<br/><br/> <ul> <li><a class="localLink"
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
