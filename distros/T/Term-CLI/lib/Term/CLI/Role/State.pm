#=============================================================================
#
#       Module:  Term::CLI::State
#
#  Description:  Role for keeping state in Term::CLI objects.
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  09/02/2022
#
#   Copyright (c) 2022 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Role::State 0.057001;

use 5.014;
use warnings;

use Types::Standard 1.000005 qw(
    HashRef
);

use Moo::Role;
use namespace::clean 0.25;

has state => (
    is       => 'lazy',
    isa      => HashRef,
    default  => sub { {} },
);

sub clear_state {
    my ($self) = @_;
    %{ $self->state } = ();
}

1;

__END__

=pod

=head1 NAME

Term::CLI::Role::State - Keep a "state" hash in Term::CLI objects

=head1 VERSION

version 0.057001

=head1 SYNOPSIS

 package Term::CLI::CommandSet {

    use Moo;

    with('Term::CLI::Role::State');
 }

 ...

 my $cmd = Term::CLI::Command->new( ... );

 $cmd->state->{'key'} = $val;

=head1 DESCRIPTION

Role for L<Term::CLI::CommandSet|Term::CLI::CommandSet>(3p) elements to represent
state across readline operations.

This role is consumed by
L<Term::CLI::CommandSet|Term::CLI::CommandSet>(3p) and thus available
in L<Term::CLI::Command|Term::CLI::Command>(3p) and L<Term::CLI>(3p)
object instances.

=head1 ATTRIBUTES

This role defines one additional attribute:

=over

=item B<state> =E<gt> I<HashRef>

Reference to an hash containing any information you want.

=back

=head1 ACCESSORS

=over

=item B<state>
X<state>

Return the C<HashRef> representing the state.

=back

=head1 METHODS

=over

=item B<clear_state>
X<clear_state>

Clear the state hash, such that subsequent calls to L<state|/state>
still return the same C<HashRef>, but without any contents.

E.g.:

    my $cli = Term::CLI->new();
    my $hash = $cli->state();

    $cli->state()->{'foo'} = 'foo';
    $hash->{'bar'}         = 'bar';

    say scalar keys %{ $hash };         # prints "2"
    say scalar keys %{ $cli->state };   # prints "2"

    $cli->clear_state();

    say scalar keys %{ $hash };         # prints "0"
    say scalar keys %{ $cli->state };   # prints "0"

=back

=head1 EXAMPLE

See F<examples/state_demo.pl> in the source distribution for an example of
how to keep state in the C<Term::CLI> object.

=head1 SEE ALSO

L<Term::CLI>(3p),
L<Term::CLI::Command>(3p),
L<Term::CLI::CommandSet>(3p).

=head1 FILES

=over

=item F<examples/state_demo.pl>

Example script that demonstrates how to keep in the C<Term::CLI> object.

=back

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2022.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=begin __PODCOVERAGE

=head1 THIS SECTION SHOULD BE HIDDEN

This section is meant for methods that should not be considered
for coverage. This typically includes things like BUILD and DEMOLISH from
Moo/Moose. It is possible to skip these when using the Pod::Coverage class
(using C<also_private>), but this is not an option when running C<cover>
from the command line.

The simplest trick is to add a hidden section with an item list containing
these methods.

=over

=item BUILD

=item DEMOLISH

=back

=end __PODCOVERAGE

=cut
