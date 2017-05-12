package Running::Commentary;

use warnings;
use strict;
use 5.014;
use Lexical::Failure;
use Keyword::Simple;

our $VERSION = '0.000005';

#====[ Implementation ]============

use Scalar::Util qw< openhandle >;
use List::Util 'max';

state $max_leader_width = 3;
state $runtime_lexhints = '@_____Running__Commentary__runtime_lexhints_____';
state $next_scope = '1';
state %scoped_flags;

# Export the SAT interface...
sub import {
    # Grab config options...
    my ($package, $fail_flag, $fail_mode)  = @_;
    _croak("Bad argument to 'use $package' (expected: 'fail' => \$fail_mode)")
        if defined $fail_flag && $fail_flag ne 'fail';

    # Handle any failure arg...
    ON_FAILURE($fail_mode // 'undef');

    # Install the API...
    no strict 'refs';
    *{caller().'::run'} = \&run;

    # Label and initialize the initial scope for run_with args...
    $^H{'Running::Commentary::scope_ID'} //= $next_scope;
    $scoped_flags{$next_scope} = [];
    $next_scope++;

    Keyword::Simple::define 'run_with', sub {
        my ($source_ref) = @_;
        ${$source_ref}
            = qq{BEGIN{ \$^H{'Running::Commentary::scope_ID'} .= ',$next_scope'; }}
            . qq{Running::Commentary::run_with }
            . ${$source_ref};
        $next_scope++;
    };
}

# Track nested calls to run()...
my @run_opts_stack = ( {} );

# Track text colouring...
my $DEF_NO_COLOUR = {};
my $DEF_COLOUR    = { MESSAGE => 'bold white', DONE => 'bold cyan', FAILED => 'bold red', OUTPUT => 'clear' };

# The entire interface...
sub run {
    # Locate innermost lexical args...
    my @lex_args = @{ _find_lex_args() };

    # Parse out explicit and lexical args....
    my ($opt_ref, @args) = _parse_args(@lex_args, @_);

    # Resolve main args...
    my ($message, $cmd)  = @args == 1 ? (undef, @args) : @args;

    # Handle misuses...
    if (!defined $cmd) {
        _croak( "Useless call to run() with no command\n (did you mean 'run_with' instead?)\n" );
    }

    # Standardize the trailing dots...
    my $message_len = length($message//q{});
    if (!$opt_ref->{-nomessage}) {
        $max_leader_width = max($max_leader_width, $message_len+3);
    }
    my $dotdotdot = '.' x ($max_leader_width - $message_len);

    # Announce the command...
    if (defined $message && !$opt_ref->{-nomessage}) {
        _nested_print( MESSAGE => $opt_ref,  $message . $dotdotdot );
    }

    # Will it work?? Will it print something??? Will there be an error???
    my ($was_successful, $output, $result_output, $error_msg);

    # Do the actual work...
    if (ref $cmd eq 'CODE') {
        # Handle -nooutput...
        local *STDOUT if $opt_ref->{-nooutput};
        local *STDERR if $opt_ref->{-nooutput};
        if ($opt_ref->{-nooutput}) {
            open *STDOUT, '>', \do{my $dev_null};
            open *STDERR, '>', \do{my $dev_null};
        }

        # If a block of code given, execute the block...
        push @run_opts_stack, $opt_ref;
        $was_successful = eval{ $cmd->(); 1 };
        pop @run_opts_stack;
        $error_msg = $@ ? 'died: ' . $@ =~ s/\n\z//r : undef;
    }
    else {
        # If a system command given, qx or echo the command string...
        $result_output
            = $output
            = $opt_ref->{-dry} ? do {                 "    > $cmd";      }
            :                    do { no warnings 'exec'; qx{$cmd 2>&1}; };

        $was_successful = ($opt_ref->{-dry} || $? == 0) ? 1 : undef;

        # On failure, clean up the error messages...
        if (!$was_successful) {
            $error_msg = ($? == -1) ? "failed to execute: " . $!
                       : ($? & 127) ? "died on signal "     . ($? & 127)
                       :              "exited with value "  . ($? >> 8);
        }
    }

    # Report the outcome...
    $output //= q{};
    if (defined $message && !$opt_ref->{-nomessage}) {
        if (length $output && !$opt_ref->{-nooutput}) {
            $output =~ s/\n?\z/\n/;
            _nested_print(OUTPUT => $opt_ref, $output);
        }
        $was_successful ? _nested_print(DONE   => $opt_ref,  "done\n")
                        : _nested_print(FAILED => $opt_ref,  "$error_msg\n");
    }
    elsif (!$opt_ref->{-nooutput} && length($output)) {
        $output =~ s/\n?\z/\n/;
        _nested_print(OUTPUT => $opt_ref,  $output);
    }

    # Return success or fail as requested...
    if ($was_successful) {
        return 1;
    }
    else {
        $error_msg = ($opt_ref->{-nomessage} ? q{} : "$message $error_msg.\n");
        if ($opt_ref->{-critical}) {
            _croak("${error_msg}Failed system call");
        }
        else {
            fail("${error_msg}Failed system call");
        }
    }
}

sub run_with {
    my $scope_ID = (caller 0)[10]{'Running::Commentary::scope_ID'};
    $scoped_flags{$scope_ID} = [ @{ _find_lex_args() }, @_];
    return;
}

sub _find_lex_args {
    # Start at the immediate caller's scope...
    my $scope_ID = (caller 1)[10]{'Running::Commentary::scope_ID'};
    my $lex_args_ref;

    # Search outwards until an active scopeis found...
    SCOPE:
    while (1) {
        $lex_args_ref = $scoped_flags{$scope_ID};
        last SCOPE if $lex_args_ref;

        $scope_ID =~ s{,[^,]+\Z}{}xms;
    }

    return $lex_args_ref // [];
}

sub _croak { require Carp; goto &Carp::croak }
sub _carp  { require Carp; goto &Carp::carp  }

sub _parse_args {
    my %opt = ( -colour => $DEF_COLOUR );
    my (@options, @args);

    # Sift args...
    while (@_) {
        my $next_arg = shift;
        if ($next_arg =~ m{\A -show (message|output) \z}xms) {
            $opt{"-no$1"} = 0;
        }
        elsif ($next_arg =~ m{\A -showall \z}xms) {
            $opt{-nomessage} = 0;
            $opt{-nooutput}  = 0;
        }
        elsif ($next_arg =~ m{\A -non?critical \z}xms) {
            $opt{-critical} = 0;
        }
        elsif ($next_arg =~ m{\A - (?:nomessage|nooutput|silent|critical|dry) \z}xms) {
            $opt{$next_arg} = 1;
        }
        elsif ($next_arg =~ m{\A -colou?r \z}xms) {
            $opt{-colour} = (@_ && ref($_[0]) eq 'HASH' ? shift : $DEF_COLOUR);
        }
        elsif ($next_arg =~ m{\A -nocolou?r \z}xms) {
            $opt{-colour} = $DEF_NO_COLOUR;
        }
        else {
            push @args, $next_arg;
        }
    }

    # -silent means both...
    if ($opt{-silent}) {
        $opt{-nooutput}  = 1;
        $opt{-nomessage} = 1;
    }

    # -dry trumps -nooutput (otherwise you won't see what the dry run would do)...
    if ($opt{-dry}) {
        $opt{-nooutput} = 0;
    }

    return \%opt, @args;
}

sub _nested_print {
    my $message_type = shift;
    my $opt_ref      = shift;
    my $message      = join "", @_;

    # Track newlines...
    state $after_nl        = 1;
    state $message_stack   = [];
    state $message_pending = 0;
    state $last_STDOUT     = 0;
    state $last_STDERR     = 0;

    # How nested???
    my $indent = q{    } x (@run_opts_stack-1);

    # Track messages...
    my $message_prefix = "";
    if ($message_type eq 'MESSAGE') {
        push @{$message_stack}, $message;
        if ($message_pending && !$after_nl) {
            $message = "\n" . $message;
        }
    }
    elsif ($message_type eq 'DONE' || $message_type eq 'FAILED') {
        my $prev_message = pop @{$message_stack};
        use Data::Dumper 'Dumper';
        if (!$message_pending || $last_STDOUT != tell(*STDOUT) || $last_STDERR != tell(*STDERR)) {
            $message_prefix = _recolour($prev_message, $opt_ref->{-colour}{MESSAGE});
            $after_nl = 1;
        }
    }
    else { # an OUTPUT
        if ($message_pending && !$after_nl) {
            $message = "\n" . $message;
        }
    }

    # Track whether start of report needs to be replicated at end of report...
    $message_pending = $message_type eq 'MESSAGE' ? 1
                     : $message_type eq 'DONE'    ? 0
                     : $message_type eq 'FAILED'  ? 0
                     :                              length($message) == 0
                     ;

    # Print everything with the appropriate indentation...
    for my $line (split /(\n)/, $message) {
        if ($after_nl) {
            print {*STDOUT} $indent, $message_prefix;
            $message_prefix = q{ } x length($message_prefix);
            $after_nl = 0;
        }
        else {
            $after_nl = $line eq "\n";
        }
        print {*STDOUT} _recolour($line, $opt_ref->{-colour}{$message_type});
    }

    # And make sure it appears...
    *STDOUT->flush();

    # Remember where we parked...
    if ($message_type eq 'MESSAGE') {
        $last_STDOUT = tell(*STDOUT);
        $last_STDERR = tell(*STDERR);
    }
}

sub _recolour {
    my ($text, $colour) = @_;
    return $text if !defined $colour || !eval{ require Term::ANSIColor };

    return Term::ANSIColor::colored($text, split /\s+/, $colour);
}


1; # Magic true value required at end of module

__END__

=head1 NAME

Running::Commentary - call C<system> cleanly, with tracking messages


=head1 VERSION

This document describes Running::Commentary version 0.000005


=head1 SYNOPSIS

    use Running::Commentary;

    # Set a lexically scoped flag for all subsequent calls...
    # (No announcements, if this flag set)
    run_with -nomessage if !$verbose;

    # Act like system(), only louder and cleaner...
    run 'Resetting' => "rm -rf '$ROOT_DIR'"
        or die "Couldn't reset";

    # Act like system(), but croak() if the command fails...
    run -critical, 'Building Makefile' => 'perl Makefile.PL';

    # Calls to run() may be nested, to allow subtasks to be tracked...
    run 'Running tests'
        => sub {
            for my $file (@profiled_files) {
                push @profiles, "$NAMING_ROOT/$file.out";
                local $ENV{NYTPROF} = "file=$profiles[-1]";

                run -nooutput, "Testing $file"
                    => "perl -d:NYTProf $profiled_path/$file >& /dev/null";
            }
    };


=head1 DESCRIPTION

This module provides a single subroutine: C<run()>
which is designed to be a more informative and less error-prone
replacement for the built-in C<system()>.

It also provides a compile-time keyword: C<run_with>
with which you can set lexically scoped default options for C<run()>.

=head1 INTERFACE

=over

=item C<< run $MESSAGE => $SYSTEM_CMD; >>

This acts like C<system $SYSTEM_CMD>, except that it returns true on success
and false on failure, and it announces what it's doing. For example:

    run 'Resetting directories' => "rm -rf @STD_DIRS"

...would first output:

    Resetting directories...

...then execute the system command, and finish the message:

    Resetting directories...done

If the command failed for some reason, the completion would reflect
the problem:

    Resetting directories...
    rm: tets: No such file or directory
    Resetting directories...exited with value 1

Or:

    Resetting directories...failed to execute: No such file or directory


=item C<< run $MESSAGE => sub {...}; >>

This form of the command expects a subroutine reference, rather than a string,
as its second argument. Once again it prints the tracking message, then
executes the subroutine, then prints the outcome.

The subroutine is run inside an C<eval> block, so any exceptions it throws
are intercepted, and reported as the outcome at the end of the tracking
message. To have exceptions inside the subroutine propagate back out of the
call to C<run()>, use the C<-critical> option (see below).

For example:

    run 'Printing your data' => sub {
        for my $datum (@data) {
            say "    $datum->{key}: $datum->{value}";
        }
    }

Would output:

    Printing your data...
        Name: Fred
        Age: 28
        Score: 87
    Printing your data...done

You can also nest calls to C<run()> using this form.
For example:

    run 'Running your request' => sub {
        for my $cmd (split /\n/, $request) {
            run "Running '$cmd'" => $cmd;
        }
    }

Would produce:

    Running your request...
        Running 'rm source'...done
        Running 'rebuild_files'...done
        Running 'make test'.......done
    Running your request...done


=item C<< run $SYSTEM_CMD; >>

=item C<< run sub {...}; >>

When called without a message, C<run()> simply executes the system
command or subroutine without printing any kind of progress message.
In other words, it merely acts as a (quietly) better C<system()>.


=item C<run_with @OPTIONS;>

The C<run_with> keyword can be called with any of the options available
to C<run()> (see L<"OPTIONS">). It takes the options given to it and
makes them the default arguments to C<run()> for the remainder of the
current lexical scope.

For example, to cause any subsequent failed command to throw an
exception...

    {
        run_with -critical;

        run "loading"     => $LOAD_CMD;
        run "checking"    => $CHECK_CMD;
        run "installing"  => $INSTALL_CMD;
        run "cleaning up" => $CLEANUP_CMD;
    }

...or to silence message printing on request:

    {
        run_with -nomessage if $opt{-quiet};

        run "loading"     => $LOAD_CMD;
        run "checking"    => $CHECK_CMD;
        run "installing"  => $INSTALL_CMD;
        run "cleaning up" => $CLEANUP_CMD;
    }


=back

Note that C<run_with> is a compile-time keyword, not a subroutine,
so it should only be called as a statement (i.e. in void context).


=head1 OPTIONS

The following options can be included anywhere in the argument list of
a call to C<run()> or C<run_with>.

=over

=item C<-nomessage>

Run the command without printing the tracking message.
Normally used as a conditional lexical option:

    run_with -nomessage if $opt{quiet};

The output of the actual system command is still
printed (unless C<-nooutput> or C<-silent> is also specified)

=item C<-showmessage>

Run the command, printing the tracking message.
Useful to turn message printing back on inside
a scope where C<-nomessage> is already in effect.


=item C<-nooutput>

Run the command without echoing any of its output.
The tracking message is still printed
(unless C<-nomessage> or C<-silent> is also specified)

=item C<-showoutput>

Run the command, echoing any output.
Useful to turn command echoing back on inside
a scope where C<-nooutput> is already in effect.

=item C<-silent>

Identical to: C<-nomessage, -nooutput>

=item C<-showall>

Identical to: C<-showmessage, -showoutput>.
Useful to override C<-silent> in a nested scope.


=item C<-critical>

Normally, if a call to C<run()> fails, it simply returns C<undef>.
However, if the C<-critical> option is specified, any call to C<run>
that fails will immediately throw an exception.

=item C<-nocritical>

Revert C<run()> to returning C<undef> on failure.
Useful to override C<-critical> in a nested scope.


=item C<-dry>

Instead of executing the specified system command, just print it out.
Useful for dry runs during development and testing.


=item C<< -colour => \%COLOUR_SPEC >>

Specify the colours to be used for messages and output. Colours
are specified as the values of the hash, with the keys indicating
what purpose each colour is to be used for. For example:

    run_with -colour => {
        MESSAGE => 'white',          # Colour for tracking messages
        DONE    => 'bold cyan',      # Colour for success messages
        FAILED  => 'yellow on_red',  # Colour for failure messages
        OUTPUT  => 'clear'           # Colour for command output
    };

The colour specifications must be single strings, which are split on
whitespace and then passed to the C<Term::ANSIColor> module. If that module
is not available, this option is silently ignored.

This option may also be spelled C<-color>.

=item C<< -nocolour >>

Print all messages and output without any special colours.

This option may also be spelled C<-nocolor>.

=back

=head1 ERROR HANDLING

On failure C<run()> normally either returns C<undef> or throws
an exception (if C<-critical> is specified).

However, C<Running::Commentary> incorporates the C<Lexical::Failure>
module, so you can also request other failure responses for any
particular scope, by passing a named argument when loading the module:

    # Report errors by confess()-ing...
    use Running::Commentary  fail => 'confess';

    # Report errors by returning a failure object...
    use Running::Commentary  fail => 'failobj';

    # Report errors by setting a flag variable...
    use Running::Commentary  fail => \$error;

    # Report errors by calling a subroutine...
    use Running::Commentary  fail => \&error_handler;

For details of the available options, see the documentation
of C<Lexical::Failure>.


=head1 DIAGNOSTICS

=over

=item C<< Bad argument to 'use Running::Commentary' >>

The module accepts only one named argument:

    use Running::Commentary  'fail' => $fail_mode;

(see L<"ERROR HANDLING">).

You apparently passed it something else.
Or perhaps misspelt 'fail'?


=item C<< Useless call to run() with no command >>

C<run()> expects at least one argument (apart from any
configuration options); namely, something to execute.
That can be either a string containing a system command,
or else a subroutine reference.

You didn't give it either of those, so the call to C<run()>
was superfluous.

Or, possibly, you wanted C<run_with> instead.

=back



=head1 CONFIGURATION AND ENVIRONMENT

Running::Commentary requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module requires Perl v5.14 or later.

It also requires the modules:
C<Lexical::Failure>, and
C<Keyword::Simple>.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-running-commentary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
