#=============================================================================
#
#       Module:  Term::CLI::ArgumentSet
#
#  Description:  Class for sets of (sub-)commands in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  05/02/18
#
#   Copyright (c) 2018 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

use 5.014_001;

package Term::CLI::Role::ArgumentSet  0.051007 {

use Modern::Perl 1.20140107;

use Types::Standard 1.000005 qw(
    ArrayRef
    InstanceOf
    Maybe
);

use Moo::Role;
use namespace::clean 0.25;

has _arguments => (
    is        => 'rw',
    writer    => '_set_arguments',
    init_arg  => 'arguments',
    isa       => Maybe[ArrayRef[InstanceOf['Term::CLI::Argument']]],
    coerce    => sub {
        # Copy the array, so the reference we store becomes
        # "internal", preventing accidental modification
        # from the outside.
        return [@{$_[0]}]
    },
);


sub arguments {
    return @{$_[0]->_arguments // []};
}


sub set_arguments {
    my $self = shift;

    $self->_set_arguments([]);
    $self->add_argument(@_);
}


sub has_arguments {
    my $self = shift;
    return ($self->_arguments and scalar @{$self->_arguments} > 0);
}


sub add_argument {
    my ($self, @arguments) = @_;
    
    if (!$self->_arguments) {
        $self->_set_arguments([]);
    }

    push @{$self->_arguments}, @arguments;
    return $self;
}


sub argument_names {
    my $self = shift;
    return map { $_->name } $self->arguments;
}


}

1;

__END__

=pod

=head1 NAME

Term::CLI::Role::ArgumentSet - Role for (sub-)commands in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 package Term::CLI::Command {

    use Moo;

    with('Term::CLI::Role::ArgumentSet');

    ...
 };

 my $cmd = Term::CLI::Command->new( ... );

 $cmd->add_argument( Term::CLI::Argument->new(...) );

 say "argument names:", join(', ', $cmd->argument_names);

=head1 DESCRIPTION

Role for L<Term::CLI::Command>(3p) elements to represent
a set of L<Term::CLI::Argument>(3p) objects.

This role is consumed by L<Term::CLI::Command>(3p).

=head1 ATTRIBUTES

This role defines two additional attributes:

=over

=item B<arguments> =E<gt> I<ArrayRef>

Reference to an array containing C<Term::CLI::Argument> object
instances that describe the parameters that the command takes,
or C<undef>.

Note that the elements of the array are copied over to an internal
array, so modifications to the I<ArrayRef> will not be seen.

=back

=head1 ACCESSORS AND PREDICATES

=over

=item B<has_arguments>
X<has_arguments>

Predicate function that returns whether or not any
L<Term::CLI::Argument|Term::CLI::Argument>s have been
added.

=item B<arguments>
X<arguments>

Return the list of 
L<Term::CLI::Argument|Term::CLI::Argument> object
references that are owned by this object.

=back

=head1 METHODS

=over

=item B<set_arguments> ( I<ARG>, ... )
X<set_arguments>

Reset the list of arguments to (I<ARG>, ...).
Each I<ARG> should be a reference to a
L<Term::CLI::Argument|Term::CLI::Argument> object.

=item B<add_argument> ( I<ARG>, ... )
X<add_argument>

Add I<ARG>(s) to the argument set.
Each I<ARG> should be a reference to a
L<Term::CLI::Argument|Term::CLI::Argument> object.

=item B<argument_names>
X<argument_names>

Return the list of (sub-)command names (in the order they were specified).

=item B<find_matches> ( I<Str> )
X<find_matches>

Return a list of all commands in this object that match the I<Str>
prefix.

=item B<find_command> ( I<Str> )
X<find_command>

Check whether I<Str> uniquely matches a command in this C<Term::CLI>
object. Returns a reference to the appropriate
L<Term::CLI::Command> object if successful; otherwise, it 
sets the objects C<error> field and returns C<undef>.

Example:

    my $sub_cmd = $cmd->find_command($prefix);
    die $cmd->error unless $sub_cmd;

=item B<try_callback> ( I<ARGS> )
X<try_callback>

Wrapper function that will call the object's C<callback> function if it
has been set, otherwise simply returns its arguments.

=back

=head1 SEE ALSO

L<Term::CLI>(3p),
L<Term::CLI::Command>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

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
