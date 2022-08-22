#=============================================================================
#
#       Module:  Term::CLI::Command
#
#  Description:  Class for (sub-)commands in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  30/01/18
#
#   Copyright (c) 2018-2022 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Command 0.058002;

use 5.014;
use warnings;

use List::Util 1.23 qw( first min );
use Types::Standard 1.000005 qw(
    ArrayRef
    CodeRef
    InstanceOf
    Maybe
    Str
);

use Term::CLI::L10N qw( loc );
use Term::CLI::Util qw( is_prefix_str get_options_from_array );

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Element';

has options => (
    is        => 'rw',
    isa       => Maybe [ ArrayRef [Str] ],
    predicate => 1
);

with qw(
    Term::CLI::Role::CommandSet
    Term::CLI::Role::ArgumentSet
    Term::CLI::Role::HelpText
    Term::CLI::Role::State
);

sub option_names {
    my ($self) = @_;
    my $opt_specs = $self->options or return ();
    my @names;
    for my $spec ( @{$opt_specs} ) {
        for my $optname ( split( qr{\|}x, $spec =~ s/^([^!+=:]+).*/$1/rx ) ) {
            push @names, length($optname) == 1 ? "-$optname" : "--$optname";
        }
    }
    return @names;
}

sub complete {
    my ( $self, $text, $state ) = @_;

    $text  //= q{};
    $state //= {};

    my $processed       = $state->{processed}     //= [];
    my $unprocessed     = $state->{unprocessed}   //= [];
    my $parsed_options  = $state->{options}       //= {};

    if ( $self->has_options ) {

        my %opt_result = get_options_from_array(
            args         => $unprocessed,
            spec         => $self->options,
            result       => $parsed_options,
            pass_through => 1,
        );

        my $double_dash = $opt_result{double_dash};

        # Check if we have to complete a command-line option.
        if ( !$double_dash && @{$unprocessed} == 0 && $text =~ /^-/x ) {
            return grep { is_prefix_str( $text, $_ ) } $self->option_names;
        }
    }

    # If the command has arguments, try to skip over them.
    if ( $self->has_arguments ) {
        my @args = $self->arguments;
        my $arg_repeat = 0;
        while ( @{$unprocessed} && @args ) {
            push @{$processed}, {
                element => $args[0],
                value   => shift @{$unprocessed},
            };
            $arg_repeat++;
            if ( $args[0]->max_occur > 0 and $arg_repeat >= $args[0]->max_occur ) {
                shift @args;
                $arg_repeat = 0;
            }
        }

        if (@args) {
            return $args[0]->complete( $text, $state );
        }
    }

    if ( $self->has_commands ) {
        if ( @{$unprocessed} == 0 ) {
            return grep { is_prefix_str( $text, $_ ) } $self->command_names;
        }
        if ( my $cmd = $self->find_command( $unprocessed->[0] ) ) {
            push @{$processed}, {
                element => $cmd,
                value => $cmd->name,
            };
            shift @{$unprocessed};
            return $cmd->complete( $text, $state );
        }
    }

    return ();
}

sub execute_command {
    my ( $self, %args ) = @_;

    $args{status} = 0;
    $args{error}  = q{};

    # Dereference and copy arguments/unparsed/options to prevent
    # unwanted side-effects.
    $args{arguments}    = [ @{ $args{arguments} } ];
    $args{unprocessed}  = [ @{ $args{unprocessed} } ];
    $args{unparsed}     = $args{unprocessed};
    $args{processed}    = [ @{ $args{processed} } ];
    $args{options}      = { %{ $args{options} } };
    $args{command_path} = [ @{ $args{command_path} } ];

    push @{ $args{command_path} }, $self;

    if ( $self->has_options ) {
        my %opt_result = get_options_from_array(
            args         => $args{unprocessed},
            spec         => $self->options,
            result       => $args{options},
            pass_through => 0,
        );

        if ( !$opt_result{success} ) {
            $args{status} = -1;
            $args{error}  = $opt_result{error_msg};
            return $self->try_callback(%args);
        }
    }

    if ( $self->has_arguments || !$self->has_commands ) {
        %args = $self->_check_arguments(%args);
        return $self->try_callback(%args) if $args{status} < 0;
    }

    return $self->try_callback(%args) if !$self->has_commands;

    if ( $self->require_sub_command || @{ $args{unprocessed} } > 0 ) {
        %args = $self->_execute_sub_command(%args);
    }
    return $self->try_callback(%args);
}

sub _too_few_args_error {
    my ( $self, $arg_spec ) = @_;

    if ( $arg_spec->max_occur == $arg_spec->min_occur ) {
        if ( $arg_spec->min_occur == 1 ) {
            return loc( "missing '[_1]' argument", $arg_spec->name );
        }
        return loc( "need [_1] '[_2]' [numerate,_1,argument]",
                $arg_spec->min_occur, $arg_spec->name, );
    }
    if ( $arg_spec->max_occur - $arg_spec->min_occur == 1 ) {
        return loc( "need [_1] or [_2] '[_3]' arguments",
            $arg_spec->min_occur, $arg_spec->max_occur, $arg_spec->name, );
    }
    if ( $arg_spec->max_occur > 1 ) {
        return loc( "need between [_1] and [_2] '[_3]' arguments",
            $arg_spec->min_occur, $arg_spec->max_occur, $arg_spec->name, );
    }
    return loc( "need at least [_1] '[_2]' [numerate,_1,argument]",
            $arg_spec->min_occur, $arg_spec->name, );
}

sub _check_arguments {
    my ( $self, %args ) = @_;

    my $unprocessed = $args{unprocessed};
    my $processed   = $args{processed};

    my @arg_spec = $self->arguments;

    if ( @arg_spec == 0 and @{$unprocessed} > 0 ) {
        return (
            %args,
            status => -1,
            error  => loc('no arguments allowed'),
        );
    }

    my $argno = 0;
    for my $arg_spec (@arg_spec) {
        if ( @{$unprocessed} < $arg_spec->min_occur ) {
            return (
                %args,
                status => -1,
                error  => $self->_too_few_args_error($arg_spec),
            );
        }

        my $args_to_check =
            $arg_spec->max_occur > 0
            ? min( $arg_spec->max_occur, scalar @{$unprocessed} )
            : scalar @{$unprocessed};

        for my $i ( 1 .. $args_to_check ) {
            my $arg = $unprocessed->[0];
            $argno++;
            my $arg_value = $arg_spec->validate($arg, \%args);
            if ( !defined $arg_value ) {
                return (
                    %args,
                    status => -1,
                    error  => "arg#$argno (" . $arg_spec->name . "), '$arg': "
                        . $arg_spec->error . q{ }
                );
            }
            push @{ $args{arguments} }, $arg_value;
            push @{ $processed }, { element => $arg_spec, value => $arg_value };
            shift @{ $unprocessed };
        }
    }

    # At this point, we have processed all our arg_spec.  The only way there
    # are any elements left in @arguments is for the last arg_spec to have
    # a max_occur that is exceeded. If the command has no sub-commands that
    # is surely an error. If it does have sub-commands, we'll leave it to
    # be parsed further.
    if ( @{$unprocessed} > 0 && !$self->has_commands ) {
        my $last_spec = $arg_spec[-1];
        return (
            %args,
            status => -1,
            error  => loc(
                "too many '[_1]' arguments (max. [_2])", $last_spec->name,
                $last_spec->max_occur,
            ),
        );
    }
    return %args;
}

sub _execute_sub_command {
    my ( $self, %args ) = @_;

    my $unprocessed = $args{unprocessed};
    my $processed   = $args{processed};

    if ( @{$unprocessed} == 0 ) {
        if ( scalar $self->commands == 1 ) {
            my ($cmd) = $self->commands;
            return (
                %args,
                status => -1,
                error => loc( "incomplete command: missing '[_1]'", $cmd->name )
            );
        }
        return ( %args, status => -1, error => loc("missing sub-command") );
    }

    my $cmd_name = $unprocessed->[0];

    my $cmd = $self->find_command($cmd_name);

    if ( !$cmd ) {
        if ( scalar $self->commands == 1 ) {
            ($cmd) = $self->commands;
            return (
                %args,
                status => -1,
                error  => loc(
                    "expected '[_1]' instead of '[_2]'", $cmd->name,
                    $cmd_name
                ),
            );
        }
        return (
            %args,
            status => -1,
            error  => loc( "unknown sub-command '[_1]'", $cmd_name )
        );
    }

    shift @{ $unprocessed };
    push @{ $processed }, { element => $cmd, value => $cmd->name };
    return $cmd->execute_command(%args);
}

1;

__END__

=pod

=head1 NAME

Term::CLI::Command - Class for (sub-)commands in Term::CLI

=head1 VERSION

version 0.058002

=head1 SYNOPSIS

 use Term::CLI::Command;
 use Term::CLI::Argument::Filename;
 use Data::Dumper;

 my $copy_cmd = Term::CLI::Command->new(
    name => 'copy',
    options => [ 'verbose!' ],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    ],
    callback => sub {
        my ($self, %args) = @_;
        print Data::Dumper->Dump([\%args], ['args']);
        return (%args, status => 0);
    }
 );

=head1 DESCRIPTION

Class for command elements in L<Term::CLI|Term::CLI>(3p).

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Element|Term::CLI::Element>(3p).

=head2 Consumes:

L<Term::CLI::Role::ArgumentSet|Term::CLI::Role::ArgumentSet>(3p),
L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet>(3p),
L<Term::CLI::Role::HelpText|Term::CLI::Role::HelpText>(3p),
L<Term::CLI::Role::State|Term::CLI::Role::State>(3p).

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<VARNAME> ... )
X<new>

Create a new C<Term::CLI::Command> object and return a reference
to it.

The B<name> attribute is required.

Other attributes are:

=over

=item B<arguments> =E<gt> I<ArrayRef>

Reference to an array containing
L<Term::CLI::Argument|Term::CLI::Argument>(3p) object
instances that describe the parameters that the command takes,
or C<undef>.

See also
L<Term::CLI::Role::ArgumentSet|Term::CLI::Role::ArgumentSet/ATTRIBUTES>.

=item B<callback> =E<gt> I<CodeRef>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

=item B<commands> =E<gt> I<ArrayRef>

Reference to an array containing C<Term::CLI::Command> object
instances that describe the sub-commands that the command takes,
or C<undef>.

See also
L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/ATTRIBUTES>.

=item B<require_sub_command> =E<gt> I<Bool>

If the command has sub-commands, it is normally required that the input
contains one of the sub-commands after this command. However, it may be
desirable to allow the command to appear "naked", i.e. without a sub-command.
For such cases, set the C<require_sub_command> to a false value.

See also
L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/ATTRIBUTES>.

=item B<options> =E<gt> I<ArrayRef>

Reference to an array containing command options in
L<Getopt::Long|Getopt::Long>(3p) style, or C<undef>.

=item B<description> =E<gt> I<Str>

Extended description of the command.

See also L<Term::CLI::Role::HelpText|Term::CLI::Role::HelpText/ATTRIBUTES>.

=item B<summary> =E<gt> I<Str>

Short description of the command.

See also L<Term::CLI::Role::HelpText|Term::CLI::Role::HelpText/ATTRIBUTES>.

=item B<usage> =E<gt> I<Str>

Static usage summary of the command.

See also L<Term::CLI::Role::HelpText|Term::CLI::Role::HelpText/ATTRIBUTES>.

(B<NOTE:> You will rarely have to specify this, as it can be determined
automatically.)

=back

=back

=head1 INHERITED METHODS

This class inherits all the attributes and accessors of
L<Term::CLI::Element|Term::CLI::Element>(3p),
L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet>(3p),
L<Term::CLI::Role::HelpText|Term::CLI::Role::HelpText>(3p),
and
L<Term::CLI::Role::ArgumentSet|Term::CLI::Role::ArgumentSet>(3p),
most notably:

=head2 Accessors

=over

=item B<has_arguments>
X<has_arguments>

See
L<has_arguments in Term::CLI::Role::ArgumentSet|Term::CLI::Role::ArgumentSet/has_arguments>.

=item B<has_callback>
X<has_callback>

See
L<has_callback in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/has_callback>.

=item B<has_commands>
X<has_commands>

See
L<has_commands in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/has_commands>.

=item B<arguments>
X<arguments>

See
L<arguments in Term::CLI::Role::ArgumentSet|Term::CLI::Role::ArgumentSet/arguments>.

Returns a list of C<Term::CLI::Argument> object instances.

=item B<commands>
X<commands>

See
L<commands in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/commands>.

Returns a list of C<Term::CLI::Command> object instances.

=item B<callback> ( [ I<CodeRef> ] )
X<callback>

See
L<callback in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/callback>.

=item B<description> ( [ I<Str> ] )
X<description>

See
L<description in Term::CLI::Role::HelpText|Term::CLI::Role::HelpText/description>.

=item B<summary> ( [ I<Str> ] )
X<summary>

See
L<summary in Term::CLI::Role::HelpText|Term::CLI::Role::HelpText/summary>.

=item B<usage> ( [ I<Str> ] )
X<usage>

See
L<description in Term::CLI::Role::HelpText|Term::CLI::Role::HelpText/description>.

=back

=head2 Others

=over

=item B<argument_names>
X<argument_names>

Return the list of argument names, in the original order.

=item B<command_names>
X<command_names>

Return the list of (sub-)command names, sorted alphabetically.

=item B<find_command> ( I<CMD> )
X<find_command>

Check whether I<CMD> is a sub-command of this command. If so,
return the appropriate C<Term::CLI::Command> reference; otherwise,
return C<undef>.

=back

=head1 METHODS

=head2 Accessors

=over

=item B<has_options>
X<has_options>

Predicate functions that return whether or not the associated
attribute has been set.

=item B<options> ( [ I<ArrayRef> ] )
X<options>

I<ArrayRef> with command-line options in L<Getopt::Long|Getopt::Long>(3p)
format.

=back

=head2 Others

=over

=item B<complete> ( I<TEXT>, I<STATE> )
X<complete>

Called by L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet>'s
L<complete_line|Term::CLI::Role::CommandSet/complete_line> method,
or another C<Term::CLI::Command>'s C<complete> function.

The method can complete options, sub-commands, and arguments.
Completions of commands and arguments is delegated to the appropriate
C<Term::CLI::Command> and L<Term::CLI::Argument|Term::CLI::Argument>
instances, resp.

=item B<option_names>
X<option_names>

Return a list of all command line options for this command.
Long options are prefixed with C<-->, and one-letter options
are prefixed with C<->.

Example:

    $cmd->options( [ 'verbose|v+', 'debug|d', 'help|h|?' ] );
    say join(' ', $cmd->option_names);
    # output: --debug --help --verbose -? -d -h -v

=item B<execute_command> ( I<KEY> =E<gt> I<VAL>, ... )

This method is called by C<Term::CLI::Role::CommandSet>'s
L<execute_line|Term::CLI::Role::CommandSet/execute_line> method.
It should not be called directly.

It accepts the same list of parameters as the
L<command callback|Term::CLI::Role::CommandSet/callback>
function
(see L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet>),
and returns the same structure.

The C<arguments> parameter (an I<ArrayRef>) should contain the words
on the command line that have not been parsed yet.

Depending on whether the object has sub-commands or arguments, the rest of
the line is parsed (possibly handing off to another sub-command), and the
results are passed to the
L<command's callback|Term::CLI::Role::CommandSet/callback>
function.

=back

=head1 SEE ALSO

L<Term::CLI::Argument|Term::CLI::Argument>(3p),
L<Term::CLI::Element|Term::CLI::Element>(3p),
L<Term::CLI::Role::ArgumentSet|Term::CLI::Role::ArgumentSet>(3p),
L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet>(3p),
L<Term::CLI::Role::HelpText|Term::CLI::Role::HelpText>(3p),
L<Term::CLI|Term::CLI>(3p),
L<Term::CLI::Util|Term::CLI::Util>(3p),
L<Getopt::Long|Getopt::Long>(3p).

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
