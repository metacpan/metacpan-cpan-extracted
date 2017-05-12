package Rule::Engine::Filter;
use Moose;

=head1 NAME

Rule::Engine::Filter - A Rule Engine Filter

=head1 ATTRIBUTES

=head2 condition

A coderef that will receive each post-rule object (in turn) and evaluate it.
If the condition returns true then the object will be returned as having passed
the rule.  If it returns false then it will not.

  Rule::Engine::Filter->new(
      condition => sub {
          my ($self, $session, $obj) = @_;
          $obj->happy ? 1 : 0
      }
  );

=cut

has 'condition' => (
    is => 'ro',
    isa => 'CodeRef',
    required => 1,
    traits => [ 'Code' ],
    handles => {
        check => 'execute_method'
    }
);

=head1 METHODS

=head2 check($obj)

Invokers the filter with an object argument.  The filter should return a true
value for a passing object and a false value for a non-passing one.

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