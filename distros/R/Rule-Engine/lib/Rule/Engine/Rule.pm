package Rule::Engine::Rule;
use Moose;

=head1 NAME

Rule::Engine::Rule - A Rule Engine Rule

=head1 ATTRIBUTES

=head2 action

The action that this rule will perform if it's condition is met.  The action
is invoked as a method and will receive two additional arguments: an instance
of the L<Rule::Engine::Session> in which it is running and the object that is
was tested.  So your first line (if you care about arguments) will need to
be:

  my ($self, $sess, $obj) = @_;

=cut

has 'action' => (
    is => 'rw',
    isa => 'CodeRef',
    traits => [ 'Code' ],
    required => 1,
    handles => {
        execute => 'execute_method'
    }
);

=head2 condition

The condition which must be met for this rule's action to be fired.  The
condition is invoked as a method and will receive two additional arguments: an
instance of the L<Rule::Engine::Session> in which it is running and the object
that is being tested.  So your first line (if you care about arguments) will
need to be:

  my ($self, $sess, $obj) = @_;

=cut

has 'condition' => (
    is => 'rw',
    isa => 'CodeRef',
    traits => [ 'Code' ],
    required => 1,
    handles => {
        evaluate => 'execute_method'
    }
);

=head2 description

Text describing this rule.

=cut

has 'description' => (
    is => 'rw',
    isa => 'Str'
);

=head2 name

The name of this rule.

=cut

has 'name' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

=head1 METHODS

=head2 evaluate

Executes this Rule's C<condition>.

=head2 execute

Executes this Rule's C<action>.

=cut

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;