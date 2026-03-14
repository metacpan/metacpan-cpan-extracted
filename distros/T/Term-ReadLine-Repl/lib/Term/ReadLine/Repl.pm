use strict;
use warnings;

package Term::ReadLine::Repl;

our $VERSION = '0.0.1';

=head1 NAME

Term::ReadLine::Repl - A batteries included interactive Term::ReadLine REPL module

=head1 SYNOPSIS

    use Term::ReadLine::Repl;

    # A simple repl
    my $repl = Term::ReadLine::Repl->new(
        {
            name       => 'myrepl',
            cmd_schema => {
                ls => {
                    exec => sub { my @list = qw(a b c); print for @list },
                },
            },
        }
    );

    # A complete repl
    $repl = Term::ReadLine::Repl->new(
        {
            name       => 'myrepl',
            prompt     => '(%s)>',
            cmd_schema => {
                stats => {
                    exec => \&get_stats,
                    args => [
                        {
                            refresh => undef,
                            host    => 'hostname',
                            guest   => 'guestname',
                            list    => 'host|guest',
                            cluster => undef,
                        }
                    ],
                },
            },
            passthrough  => 1,
            hist_file    => '/path/to/.hist_file',
            get_opts     => \&arg_parse,
            custom_logic => \&my_custom_loop_ctrl,
        }
    );

    $repl->run();

=head1 DESCRIPTION

C<Term::ReadLine::Repl> provides a simple framework for building interactive
command-line REPLs (Read-Eval-Print Loops) on top of L<Term::ReadLine>. It
handles tab completion, command history, a built-in help system, and optional
passthrough to shell commands, so you can focus on defining your commands
rather than plumbing the terminal interaction.

=head2 Overview

You define your commands and their arguments via the C<cmd_schema> hashref
passed to C<new()>. Each command maps to an C<exec> coderef that is called
when the user types that command, and an optional C<args> structure that drives
tab completion. Once constructed, calling C<run()> drops the user into an
interactive prompt.

The module handles the following automatically:

=over 4

=item *

B<Tab completion> - command names and their arguments are completed from the
C<cmd_schema> definition. Passthrough commands (prefixed with C<!>) are
excluded.

=item *

B<Command history> - input history is maintained in-session via
L<Term::ReadLine>, and can be persisted across sessions by supplying a
C<hist_file> path.

=item *

B<Built-in commands> - C<help> and C<quit>/C<exit> are injected automatically
into every REPL.

=item *

B<Shell passthrough> - when C<passthrough> is enabled, any input prefixed with
C<!> is forwarded directly to the system shell, making it easy to run one-off
shell commands without leaving the REPL.

=item *

B<Custom loop hooks> - the C<get_opts> and C<custom_logic> callbacks let you
plug L<Getopt::Long> parsing and arbitrary mid-loop logic into the REPL without
having to subclass or modify the module.

=back

=head1 CONSTRUCTOR

=over 4

=item C<new(\%args)>

Creates and returns a new C<Term::ReadLine::Repl> object. Accepts a hashref
with the following keys:

=over 4

=item C<name> (required)

A string used as the name of the REPL, displayed in the welcome message and
optionally interpolated into the prompt via C<%s>.

=item C<cmd_schema> (required)

A hashref defining the available commands. Each key is a command name, and
its value is a hashref with the following keys:

=over 4

=item C<exec> (required)

A coderef that is called when the command is invoked. Any arguments supplied
on the command line (after the command name) are passed to the coderef.

=item C<args> (optional)

An arrayref of hashrefs describing the command's arguments for tab completion.
Each hashref maps an argument name to either C<undef> (flag, no value expected)
or a string describing the expected value (used as a completion hint).

=back

=item C<prompt> (optional)

A C<sprintf>-style format string for the prompt. C<%s> is replaced with the
REPL name. Defaults to C<(repl)>>.

=item C<passthrough> (optional)

When set to a true value, any input beginning with C<!> is passed directly to
the system shell. For example, C<!ls -la> would run C<ls -la>. Defaults to C<0>.

=item C<hist_file> (optional)

Path to a file used for persistent command history. History is loaded on
startup and saved on exit. If not specified, history is not persisted.

=item C<get_opts> (optional)

A coderef to a L<Getopt::Long> parsing function. When provided, it is called
before each command dispatch with C<@ARGV> populated from the current input line.

=item C<custom_logic> (optional)

A coderef invoked on each loop iteration before command dispatch. Receives an
arrayref of the parsed input tokens. May return a hashref with the following
optional keys:

=over 4

=item C<action>

Set to C<'next'> to skip to the next loop iteration, or C<'last'> to exit
the REPL loop.

=item C<schema>

A replacement C<cmd_schema> hashref to swap in for subsequent iterations.

=back

=back

=back

=head1 METHODS

=over 4

=item C<run()>

Launches the interactive REPL session. Prints a welcome message, then enters
the read-eval-print loop until the user types C<quit>, C<exit>, or C<EOF>.
Saves history on exit if C<hist_file> was configured.

=item C<validate_args(\%args)>

Validates the constructor argument hashref. Croaks with a descriptive message
if any required arguments are missing or if any values have an unexpected type.
Called automatically by C<new()>.

=back

=head1 BUILT-IN COMMANDS

The following commands are automatically added to every REPL:

=over 4

=item C<help>

Prints all available commands and their arguments.

=item C<quit> / C<exit>

Exits the REPL session.

=back

=head1 TAB COMPLETION

Tab completion is provided automatically for command names and their defined
arguments. Completions are driven by the C<args> key in each command's schema.
Passthrough commands (those beginning with C<!>) are excluded from completion.

=head1 AUTHORS

Written by John R. Copyright (c) 2026

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut

use Data::Dumper;
use Term::ANSIColor;
use Term::ReadLine;
use Carp qw(croak);

sub new {
    my ($class, $args) = @_;

    $class->validate_args($args);

    my $self = {
        name         =>  $args->{name} // 'repl',
        prompt       =>  defined $args->{prompt} ? sprintf $args->{prompt}, $args->{name} : '(repl)>',
        cmd_schema   =>  $args->{cmd_schema},
        passthrough  =>  $args->{passthrough} // 0,
        hist_file    =>  $args->{hist_file},
        get_opts     =>  $args->{get_opts},
        custom_logic =>  $args->{custom_logic},
    };

    # Add builtin commands.
    $self->{cmd_schema}{help}={}; 
    $self->{cmd_schema}{quit}={}; 

    bless $self, $class;

    return $self;
}

sub validate_args {
    my ($self, $args) = @_;

    # Ensure name and cmd_schema exist (required args)
    croak "name is a required arg!" unless exists $args->{name} && defined $args->{name};
    croak "cmd_schema is a required arg!" unless exists $args->{cmd_schema} && defined $args->{cmd_schema};

    # Ensure cmd_schema is a hashref
    croak "cmd_schema is NOT a hashref!" unless ref $args->{cmd_schema} eq 'HASH';

    # Ensure each cmd has an exec key and is a coderef
    for my $cmd (keys %{$args->{cmd_schema}}) {
        my $schema = $args->{cmd_schema}{$cmd};

        croak "'$cmd' missing exec key!" unless defined $schema->{exec};

        croak "'$cmd' exec is NOT a coderef!" unless ref $schema->{exec} eq 'CODE';

        # Ensure that args is an array
        if (exists $schema->{args} && defined $schema->{args}) {
            croak "'$cmd' args is NOT a arrayref!" unless ref $schema->{args};

            croak "'$cmd' args array is empty!" if scalar @{$schema->{args}} < 1;

            for my $arg (@{$schema->{args}}) {
                croak "'$cmd' non-hashref found in args arrayref!" unless ref $arg eq 'HASH';
            }
        }
    }

    # Ensure get_ops is a coderef if present
    if (exists $args->{get_opts} && defined $args->{get_opts}) {
        croak "get_opts is NOT a coderef!" unless ref $args->{get_opts} eq 'CODE';
    }
}

sub run {
    my ($self) = @_;

    my $term = Term::ReadLine->new('Simple Shell');
    my $attribs = $term->Attribs;

    $self->_read_history($term) if defined $self->{hist_file};

    print colored(sprintf("Welcome to $self->{name} shell!"), 'green underline italic bold'), "\n";
    print colored(sprintf("Type 'help' for more options, <TAB> to auto complete."), 'green bold'), "\n";

    # Tab completion.
    $attribs->{completion_function} = sub { return $self->_tab_complete(@_) };
    my $prompt = colored(sprintf("$self->{prompt} "), 'green');

    $|++;

    # Simple REPL loop.
    while (defined (my $input = $term->readline($prompt))) {
        chomp $input;
        last if ($input =~ /^(exit|quit)$/);

        next unless $input;

        if ($input =~ 'help') {
            $self->_help();
            next;
        }

        my @args = split(/\s+/, $input);

        # Command line passthrough.
        if ($self->{passthrough} && @args && $args[0] =~ /^\!/) {
            $args[0] =~ s/\!//g;
            system(@args);
            next;
        }

        if (defined $self->{get_opts}) {
            # Clobber ARGV for getopts parsing, doesn't matter because client
            # code parser will slurp args outta @ARGV again right away.
            @ARGV = @args;
            $self->{get_opts}->();
        }

        # Custom loop logic.
        # User custom function can return a hashref like the following.
        # { 
        #     action => next|last|undef,
        #     schema => $schema,  # Where schema is a hashref containing any changes your custom logic might make to cmd_schema.
        # }
        if (defined $self->{custom_logic}) {
            my $result = eval {
                $self->{custom_logic}->(\@args);
            };

            if (defined $result && ref $result eq 'HASH') {
                if (defined $result->{action}) {
                    next if $result->{action} eq 'next';
                    last if $result->{action} eq 'last';
                }
                if (defined $result->{schema}) {
                    $self->{cmd_schema} = $result->{schema};
                }
            }
        }

        my $cmd = shift @args;

        if (exists $self->{cmd_schema}{$cmd}) {
            $self->{cmd_schema}{$cmd}{exec}->(@args);
        } else {
            print "No such command '$cmd' run 'help' to see options\n";
        }
    }
    print "\n" . colored(sprintf("Goodbye!"), 'green bold underline italic'), "\n";
    $self->_save_history($term) if defined $self->{hist_file};
}

sub _tab_complete {
    my ($self, $text, $line) = @_;

    # Don't auto complete on passthroughs.
    return () if $line =~ /^\!/;

    # Split the current line into words.
    my @words = split(/\s+/, $line);
    my @complete_words = @words;
    pop @complete_words unless $line =~ /\s$/;

    if (@words >= 1) {
        my $cmd = $words[0];
        my $arg_index = (scalar(@complete_words) - 1);  # -1 because first word is always $cmd

        if ($self->{cmd_schema}{$cmd}) {
            my $schema = $self->{cmd_schema}{$cmd};

            # None of the below make sense unless we have args.
            return () unless $schema->{args};

            my $opt_arg_index = $arg_index -1;

            # If next word matches args key, go into optargs
            if (scalar @complete_words && exists $schema->{args}[$opt_arg_index]{$complete_words[-1]}) {
                my $opt_arg = $schema->{args}[$opt_arg_index]{$complete_words[-1]};
                return "<$opt_arg>" if defined $opt_arg;
            }

            # Count number of opt args in command to subtract from $arg_index.
            my $num_opt_args=0;
            my @all_opt_args;
            for my $arg (@{$schema->{args}}) {
                for my $key (keys %{$arg}) {
                    my $value = $arg->{$key};
                    push @all_opt_args, $key if defined $value;
                }
            }
            for my $word (@complete_words) {
                for my $opt_arg (@all_opt_args) {
                    $num_opt_args++ if ($word eq $opt_arg);
                }
            }
            $arg_index = $arg_index - $num_opt_args;

            my $args = @{$schema->{args}}[$arg_index];
            my @keys = keys %{$args};
            return () unless @keys;
            return grep { /^\Q$text/ } @keys;
        }
    }

    # If we're completing the first word
    if (@words <= 1) {
        my $cmd = $words[0];
        my @cmds = keys %{$self->{cmd_schema}};
        return grep { /^\Q$text/ } @cmds;
    }

    # No completion For anything beyond second word.
    return ();
}


sub _help {
    my ($self) = @_;

    my $output;
    for my $cmd (keys %{$self->{cmd_schema}}) {
        $output .= "$cmd\n";
        next unless $self->{cmd_schema}{$cmd}{args};
        for my $args (sort @{$self->{cmd_schema}{$cmd}{args}} ) {
            $output .= "    ";
            for my $arg (keys %{$args}) {
                my $opt = $args->{$arg};
                $output .= "$arg";
                $output .= defined $opt ? "=<$opt>, " : ", ";
            }
            substr($output, -1) = "";  # Remove trailing space
            substr($output, -1) = "";  # Remove trailing ,
            $output .= "\n";
        }
    }
    print "$output";
}

sub _read_history {
    my ($self, $term) = @_;

    if (-f $self->{hist_file}) {
        open my $fh, '<', $self->{hist_file} or warn "Couldn't read auto bal history file: $!";
        while (my $line = <$fh>) {
            chomp $line;
            $term->addhistory($line);
        }
        close $fh;
    }
}

sub _save_history {
    my ($self, $term) = @_;

    my $attribs = $term->Attribs;

    open my $fh, '>>', $self->{hist_file} or warn "Couldn't save auto bal history: $!";
    if ($term->ReadLine =~ /Gnu/) {
        for my $line ($term->GetHistory) {
            print $fh "$line\n";
        }
    } 
    close $fh;
}

1;
