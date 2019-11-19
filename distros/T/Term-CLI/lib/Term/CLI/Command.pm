#=============================================================================
#
#       Module:  Term::CLI::Command
#
#  Description:  Class for (sub-)commands in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  30/01/18
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

package Term::CLI::Command  0.051007 {

use Modern::Perl 1.20140107;
use List::Util 1.38 qw( first min );
use Getopt::Long 2.42 qw( GetOptionsFromArray );
use Types::Standard 1.000005 qw(
    ArrayRef
    CodeRef
    InstanceOf
    Maybe
    Str
);

use Term::CLI::L10N;

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Element';

has options => (
    is => 'rw',
    isa => Maybe[ArrayRef[Str]],
    predicate => 1
);


with ('Term::CLI::Role::CommandSet');
with ('Term::CLI::Role::ArgumentSet');
with ('Term::CLI::Role::HelpText');


sub option_names {
    my $self = shift;
    my $opt_specs = $self->options or return ();
    my @names;
    for my $spec (@$opt_specs) {
        for my $optname (split(qr/\|/, $spec =~ s/^([^!+=:]+).*/$1/r)) {
            push @names, length($optname) == 1 ? "-$optname" : "--$optname";
        }
    }
    return @names;
}


sub complete_line {
    my ($self, @words) = @_;

    my $partial = $words[$#words] // '';

    if ($self->has_options) {

        Getopt::Long::Configure(qw(bundling require_order pass_through));

        my $opt_specs = $self->options;

        my %parsed_opts;

        my $has_terminator;
        if ($Getopt::Long::VERSION < 2.51) {
            # Getopt::Long before 2.51 removes '--' from word list;
            # Try to work around the bug. Can still be fooled by
            # "--foo --" if "--foo" takes an argument. :-/
            $has_terminator = first { $_ eq '--' } @words[0..$#words-1];
            eval { GetOptionsFromArray(\@words, \%parsed_opts, @$opt_specs) };
        }
        else {
            eval { GetOptionsFromArray(\@words, \%parsed_opts, @$opt_specs) };
            if (@words > 1 && $words[0] eq '--') {
                $has_terminator = shift @words;
            }
        }
        if (!$has_terminator && @words <= 1 && $partial =~ /^-/) {
            # We have to complete a command-line option.
            return grep { rindex($_, $partial, 0) == 0 } $self->option_names;
        }
    }

    # If the command has arguments, try to skip over them.
    if ($self->has_arguments) {
        my @args = $self->arguments;
        my $n = 0;
        while (@words > 1) {
            last if @args == 0;
            shift @words;
            $n++;
            if ($args[0]->max_occur > 0 and $n >= $args[0]->max_occur) {
                shift @args;
                $n = 0;
            }
        }

        if (@args) {
            return $args[0]->complete($words[0]);
        }
    }

    if ($self->has_commands) {
        if (@words <= 1) {
            return grep { rindex($_, $partial, 0) == 0 } $self->command_names;
        }
        elsif (my $cmd = $self->find_command($words[0])) {
            return $cmd->complete_line(@words[1..$#words]);
        }
    }

    return ();
}


sub execute {
    my ($self, %args) = @_;

    $args{status} = 0;
    $args{error}  = '';

    # Dereference and copy arguments/unparsed/options to prevent
    # unwanted side-effects.
    $args{arguments}    = [@{$args{arguments}}];
    $args{unparsed}     = [@{$args{unparsed}}];
    $args{options}      = {%{$args{options}}};
    $args{command_path} = [@{$args{command_path}}];

    push @{$args{command_path}}, $self;

    if ($self->has_options) {
        my $opt_specs = $self->options;

        Getopt::Long::Configure(qw(bundling require_order no_pass_through));

        my $error = '';
        my $ok = do {
            local( $SIG{__WARN__} ) = sub { chomp($error = join('', @_)) };
            GetOptionsFromArray($args{unparsed}, $args{options}, @$opt_specs);
        };

        if (!$ok) {
            $args{status} = -1;
            $args{error} = $error;
        }
    }

    if ($args{status} >= 0) {
        if ($self->has_arguments or !$self->has_commands) {
            %args = $self->_check_arguments(%args);
        }
    }
    if ($args{status} >= 0 and $self->has_commands) {
        %args = $self->_execute_command(%args);
    }
    return $self->try_callback( %args );
}


sub _too_few_args_error {
    my ($self, $arg_spec) = @_;

    if ($arg_spec->max_occur == $arg_spec->min_occur) {
        if ($arg_spec->min_occur == 1) {
            return loc("missing '[_1]' argument", $arg_spec->name);
        }
        else {
            return loc("need [_1] '[_2]' [numerate,_1,argument]",
                $arg_spec->min_occur, $arg_spec->name,
            );
        }
    }
    elsif ($arg_spec->max_occur - $arg_spec->min_occur == 1) {
        return loc("need [_1] or [_2] '[_3]' arguments",
            $arg_spec->min_occur,
            $arg_spec->max_occur,
            $arg_spec->name,
        );
    }
    elsif ($arg_spec->max_occur > 1) {
        return loc("need between [_1] and [_2] '[_3]' arguments",
            $arg_spec->min_occur,
            $arg_spec->max_occur,
            $arg_spec->name,
        );
    }
    else {
        return loc("need at least [_1] '[_2]' [numerate,_1,argument]",
            $arg_spec->min_occur,
            $arg_spec->name,
        );
    }
}


sub _check_arguments {
    my ($self, %args) = @_;

    my $unparsed = $args{unparsed};

    my @arg_spec = $self->arguments;

    if (@arg_spec == 0 and @$unparsed > 0) {
        return (%args,
            status => -1,
            error => loc('no arguments allowed'),
        );
    }

    my $argno = 0;
    my @parsed_args;
    for my $arg_spec (@arg_spec) {
        if (@$unparsed < $arg_spec->min_occur) {
            return (%args,
                status => -1,
                error => $self->_too_few_args_error($arg_spec),
            );
        }

        my $args_to_check
            = $arg_spec->max_occur > 0
                ? min($arg_spec->max_occur, scalar @$unparsed)
                : scalar @$unparsed;

        for my $i (1..$args_to_check) {
            my $arg = $unparsed->[0];
            $argno++;
            my $arg_value = $arg_spec->validate($arg);
            if (!defined $arg_value) {
                return (%args,
                    status => -1,
                    error => "arg#$argno, '$arg': " . $arg_spec->error
                           . " ".loc("for")." '" . $arg_spec->name . "'"
                );
            }
            push @{$args{arguments}}, $arg_value;
            shift @$unparsed;
        }
    }

    # At this point, we have processed all our arg_spec.  The only way there
    # are any elements left in @arguments is for the last arg_spec to have
    # a max_occur that is exceeded. If the command has no sub-commands that
    # is surely an error. If it does have sub-commands, we'll leave it to
    # be parsed further.
    if (@$unparsed > 0 and !$self->has_commands) {
        my $last_spec = $arg_spec[$#arg_spec];
        return (%args, status => -1,
            error => loc("too many '[_1]' arguments (max. [_2])",
                $last_spec->name,
                $last_spec->max_occur,
            ),
        );
    }
    return %args;
}


sub _execute_command {
    my ($self, %args) = @_;

    my $unparsed = $args{unparsed};

    if (@$unparsed == 0) {
        if (scalar $self->commands == 1) {
            my ($cmd) = $self->commands;
            return (%args, status => -1,
                error => loc("incomplete command: missing '[_1]'", $cmd->name)
            );
        }
        return (%args, status => -1, error => loc("missing sub-command"));
    }

    my $cmd_name = $unparsed->[0];

    my $cmd = $self->find_command($cmd_name);

    if (!$cmd) {
        if (scalar $self->commands == 1) {
            ($cmd) = $self->commands;
            return (%args, status => -1,
                error => loc(
                    "expected '[_1]' instead of '[_2]'",
                    $cmd->name,
                    $cmd_name
                ),
            );
        }
        return (%args,
            status => -1,
            error => loc("unknown sub-command '[_1]'", $cmd_name)
        );
    }

    shift @$unparsed;
    return $cmd->execute(%args);
}


}

1;

__END__

=pod

=head1 NAME

Term::CLI::Command - Class for (sub-)commands in Term::CLI

=head1 VERSION

version 0.051007

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

Class for command elements in L<Term::CLI>(3p).

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Element>(3p).

=head2 Consumes:

L<Term::CLI::Role::ArgumentSet>(3p),
L<Term::CLI::Role::CommandSet>(3p),
L<Term::CLI::Role::HelpText>(3p).

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

Reference to an array containing L<Term::CLI::Argument>(3p) object
instances that describe the parameters that the command takes,
or C<undef>.

See also L<Term::CLI::Role::ArgumentSet|Term::CLI::Role::ArgumentSet/ATTRIBUTES>.

=item B<callback> =E<gt> I<CodeRef>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

=item B<commands> =E<gt> I<ArrayRef>

Reference to an array containing C<Term::CLI::Command> object
instances that describe the sub-commands that the command takes,
or C<undef>.

See also L<Term::CLI::Role::ArgumentSet|Term::CLI::Role::ArgumentSet/ATTRIBUTES>.

=item B<options> =E<gt> I<ArrayRef>

Reference to an array containing command options in
L<Getopt::Long>(3p) style, or C<undef>.

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
L<Term::CLI::Element>(3p),
L<Term::CLI::Role::CommandSet>(3p),
L<Term::CLI::Role::HelpText>(3p),
and
L<Term::CLI::Role::ArgumentSet>(3p),
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

I<ArrayRef> with command-line options in L<Getopt::Long>(3p) format.

=back

=head2 Others

=over

=item B<complete_line> ( I<CLI>, I<WORD>, ... )
X<complete_line>

I<CLI> is a reference to the top-level L<Term::CLI> instance.

The I<WORD> arguments make up the parameters to this command.
Given those, this method attempts to generate possible completions
for the last I<WORD> in the list.

The method can complete options, sub-commands, and arguments.
Completions of commands and arguments is delegated to the appropriate
L<Term::CLI::Command> and L<Term::CLI::Argument> instances, resp.

=item B<option_names>
X<option_names>

Return a list of all command line options for this command.
Long options are prefixed with C<-->, and one-letter options
are prefixed with C<->.

Example:

    $cmd->options( [ 'verbose|v+', 'debug|d', 'help|h|?' ] );
    say join(' ', $cmd->option_names);
    # output: --debug --help --verbose -? -d -h -v

=item B<execute> ( I<ARGS> )

This method is called by L<Term::CLI::execute|Term::CLI/execute>. It
should not be called directly.

It accepts the same list of parameters as the 
L<command callback|Term::CLI::Role::CommandSet/callback>
function (see
L<Term::CLI::Role::CommandSet>), and returns the same structure.

The C<arguments> I<ArrayRef> should contain the words on the command line
that have not been parsed yet.

Depending on whether the object has sub-commands or arguments, the rest of
the line is parsed (possibly handing off to another sub-command), and the
results are passed to the
L<command's callback|Term::CLI::Role::CommandSet/callback>
function.

=back

=head1 SEE ALSO

L<Term::CLI::Argument>(3p),
L<Term::CLI::Element>(3p),
L<Term::CLI::Role::ArgumentSet>(3p),
L<Term::CLI::Role::CommandSet>(3p),
L<Term::CLI::Role::HelpText>(3p),
L<Term::CLI>(3p),
L<Getopt::Long>(3p).

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
