package Shell::Base;

# ----------------------------------------------------------------------
# Shell::Base - A generic class to build line-oriented command interpreters.
# $Id: Base.pm,v 1.5 2004/08/26 20:01:47 dlc Exp $
# ----------------------------------------------------------------------
# Copyright (C) 2003 darren chamberlain <darren@cpan.org>
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# ----------------------------------------------------------------------

use strict;
use vars qw( $VERSION $REVISION $PROMPT
             $RE_QUIT $RE_HELP $RE_SHEBANG
            );

use Carp qw(carp croak);
use Env qw($PAGER $SHELL $COLUMNS);
use IO::File;
use File::Basename qw(basename);
use Term::Size qw(chars);
use Text::Shellwords qw(shellwords);

$VERSION      = 0.05;   # $Date: 2004/08/26 20:01:47 $
$REVISION     = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;
$RE_QUIT      = '(?i)^\s*(exit|quit|logout)' unless defined $RE_QUIT;
$RE_HELP      = '(?i)^\s*(help|\?)'          unless defined $RE_HELP;
$RE_SHEBANG   = '^\s*!\s*$'                  unless defined $RE_SHEBANG;

# ----------------------------------------------------------------------
# import()
#
# The default import method, called when the class is use'd.  This 
# sets the default prompt, which can be overridden by a subclass as
# necessary.
#
# There is a pseudo-function called "shell" that can be imported by
# classes which use a Shell::Base-originated class:
#
#   use My::Shell qw(shell);
#
#   shell();
#
# Tests: t/import.t
# ----------------------------------------------------------------------
sub import {
    my $class = shift;

    if (@_ && grep /^shell$/, @_) {
        # Requested as use Shell::Base qw(shell), or
        # from the command line as -MShell::Base=shell
        # Install the shell function into the caller's
        # namespace.  However, there is no shell
        # function; we create one here.  shell would
        # be invoked by the caller as:
        #
        #   shell(@args);
        #
        # i.e., without a package, so we need to pass
        # a package in.  A closure will do nicely.

        no strict qw(refs);
        my $caller = caller;
        *{"$caller\::shell"} = sub {
            $class->new(@_)->run();
        };
    }
    
    $PROMPT = "($class) \$ " unless defined $PROMPT;
}

# ----------------------------------------------------------------------
# new(\%args)
#
# Basic constructor.
#
# new() calls initialization methods:
#
#   - init_rl
#
#     o Initializes the Term::ReadLine instance
#
#   - init_rcfiles
#
#     o Initializes rc files (anything in RCFILES)
#
#   - init_help
#
#     o Initializes the list of help methods
#
#   - init_completions
#
#     o Initializes the list of tab-completable commands
#
#   - init
#
#     o Subclass-specific intializations.
#
# Tests: t/new.t
#        All tests instantiate objects, so new is tested indirectly
#        by all tests.
# ----------------------------------------------------------------------
sub new {
    my $class = shift;
    my $args  = UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };

    my @size = chars();
    my $self  = bless {
        ARGS        => $args,
        COMPLETIONS => undef,           # tab completion
        CONFIG      => { },
        HELPS       => undef,           # help methods
        HISTFILE    => undef,           # history file
        PAGER       => undef,           # pager
        PROMPT      => $PROMPT,         # default prompt
        TERM        => undef,           # Term::ReadLine instance
        SIZE        => \@size,          # Terminal size
        COLUMNS     => $size[0],
        ROWS        => $size[1],
    } => $class;

    $self->init_rl($args);
    $self->init_rcfiles($args);
    $self->init_completions($args);
    $self->init_help($args);
    $self->init($args);

    return $self;
}

# ----------------------------------------------------------------------
# init_rl(\%args)
#
# Initialize Term::ReadLine.  Subclasses can override this method if
# readline support is not needed or wanted.
#
# Tests: t/init_rl.t
# ----------------------------------------------------------------------
sub init_rl {
    my ($self, $args) = @_;
    my ($term, $attr);

    require Term::ReadLine;
    $self->term($term = Term::ReadLine->new(ref $self));

    # Setup default tab-completion function.
    $attr = $term->Attribs;
    $attr->{completion_function} = sub { $self->complete(@_) };

    if (my $histfile = $args->{ HISTFILE }) {
        $self->histfile($histfile);
        $term->ReadHistory($histfile);
    }

    return $self;
}

# ----------------------------------------------------------------------
# init_rcfiles(\%args)
#
# Initialize rc files, which are in name = value format.  The RCFILES
# member of %args should contain a reference to a rc files.  These
# will be read in the order defined, and all elements defined within
# will be present in $self->{ CONFIG }, and accessible via $self->config.
#
# test: t/init_rcfiles.t
# XXX Refactor this into init_rcfiles and parse_rcfile!
# ----------------------------------------------------------------------
sub init_rcfiles {
    my ($self, $args) = @_;
    my (@rcfiles, $rcfile);

    return unless defined $args->{ RCFILES };

    # Ensure we have an array
    $args->{ RCFILES } = [ $args->{ RCFILES } ]
        unless ref($args->{ RCFILES }) eq 'ARRAY';

    @rcfiles = @{ $args->{ RCFILES } };

    for $rcfile (@rcfiles) {
        _merge_hash($self->{ CONFIG },
             scalar $self->parse_rcfile($rcfile));
    }
}

# ----------------------------------------------------------------------
# parse_rcfile($filename)
#
# Parses a config file, and returns a hash of config values.
#
# test: t/parse_rcfile.t
# ----------------------------------------------------------------------
sub parse_rcfile {
    my ($self, $rcfile) = @_;
    my %config = ();

    my $buffer = "";
    my $rc = IO::File->new($rcfile)
        or next;

    while (defined(my $line = <$rc>)) {
        chomp $line;            
        $line =~ s/#.*$//;

        if (length $buffer && length $line) {
            $line = $buffer . $line;
        }

        # Line continuation
        if ($line =~ s/\\$//) {
            $buffer = $line;
            next;
        } else {
            $buffer = '';
        }

        next unless length $line;

        my ($name, $value) = $line =~ /^\s*(.*?)\s*(?:=>?\s*(.*))?$/;
        $name = lc $name;
        unless (defined $value) {
            if ($name =~ s/^no//) {
                $value = 0;
            }
            else {
                $value = 1;
            }
        }
        $config{ $name } = $value;
    }

    return wantarray ? %config : \%config;
}

# ----------------------------------------------------------------------
# init_help()
#
# Initializes the internal HELPS list, which is a list of all the
# help_foo methods defined within the current class, and all the
# classes from which the current class inherits from.
#
# Tests: t/init_help.t
# ----------------------------------------------------------------------
sub init_help {
    my $self = shift;
    my $class = ref $self || $self;
    my %uniq = ();

    no strict qw(refs);
    $self->helps(
        grep { ++$uniq{$_} == 1 }
        map { s/^help_//; $_ }
        grep /^help_/,
        map({ %{"$_\::"} } @{"$class\::ISA"}),
        keys  %{"$class\::"});
}

# ----------------------------------------------------------------------
# init_completions()
#
# Initializes the internal COMPLETIONS list, which is used by the 
# complete method, which is, in turn, used by Term::ReadLine to
# do tab-compleion.
#
# Tests: t/init_completions.t
# ----------------------------------------------------------------------
sub init_completions {
    my $self = shift;
    my $class = ref $self || $self;
    my %uniq = ();

    no strict qw(refs);
    $self->completions(
        sort 
        "help",
        grep { ++$uniq{$_} == 1 }
        map { s/^do_//; $_ }
        grep /^do_/,
        map({ %{"$_\::"} } @{"$class\::ISA"}),
        keys  %{"$class\::"});
}

# ----------------------------------------------------------------------
# init(\%args)
#
# Basic init method; subclasses can override this as needed.  This is
# the place to do any subclass-specific initialization.
#
# Command completion is initialized here, so subclasses should call
# $self->SUPER::init(@_) within overridden init methods if they want
# this completion to be setup.
#
# Tests: none (why?)
# ----------------------------------------------------------------------
sub init {
    my ($self, $args) = @_;

    return $self;
}

# ----------------------------------------------------------------------
# run()
#
# run is the main() of the interpreter.  Its duties are:
#
#   - Print the results of $self->intro(), if defined,
#     via $self->print()
#
#   - Get a line of input, via $self->term->readline.
#     This begins the run loop.
#
#     o Pass this line to $self->precmd for massaging
#
#     o Pass this line to $self->parseline for splitting into
#       (command_name, variable assignments, arguments)
#
#     o Check contents of command_name; there are a few special
#       cases:
#
#         + If the line is a help line (matches $RE_HELP), then
#           call $self->help(@args)
#
#         + If the line is a quit line (matches $RE_QUIT), then
#           call $self->quit()
#
#         + If the line is a bang (matches $RE_SHEBANG), then
#           invoke $self->do_shell()
#
#         + Otherwise, attempt to invoke $self->do_$command_name
#
#     o The output from whichever of the above is chosen will be
#       passed to $self->postcmd for final processing
#
#     o If the output from $self->postcmd is not undefined, it
#       will be printed via $self->print()
#
#     o The prompt is reset, and control returns to the top of
#       the run loop.
#
# Tests: none (Dunno how, without requiring Expect (yuck))
# ----------------------------------------------------------------------
sub run {
    my $self = shift;
    my ($prompt, $blurb);

    $prompt = $self->prompt;
    $blurb = $self->intro;

    
    if (defined $blurb) {
        chomp $blurb;
        $self->print("$blurb\n");
    }

    while (defined (my $line = $self->readline($prompt))) {
        my (@args, $cmd, $env, $output);

        $line = $self->precmd($line);

        ($cmd, $env, @args) = $self->parseline($line);
        local %ENV = (%ENV, %$env);

        if (! length($cmd)) {
            $output = $self->emptycommand();
        }
        elsif ($cmd =~ /$RE_HELP/) {
            $output = $self->help(@args);
        }
        elsif ($cmd =~ /$RE_QUIT/) {
            $self->quit;
        }
        else {
            if ($cmd =~ /$RE_SHEBANG/) {
                $cmd = "shell";
            }
            eval {
                my $meth = "do_$cmd";
                $output = $self->$meth(@args);
            };
            if ($@) {
                $output = sprintf "%s: Bad command or filename", $self->progname;
                my $err = $@;
                chomp $err;
                warn "$output ($err)\n";
                eval {
                    $output = $self->default($cmd, @args);
                };
            }
        }

        $output = $self->postcmd($output);
        $output =~ s/\n*$//;

        chomp $output;
        $self->print("$output\n") if defined $output;

        # In case precmd or postcmd modified the prompt,
        # we recollect it before displaying it.
        $prompt = $self->prompt();
    }

    $self->quit();
}

# ----------------------------------------------------------------------
# readline()
#
# Calls readline on the internal Term::ReadLine instance.  Provided
# as a separate method within Shell::Base so that subclasses which
# do not want to use Term::ReadLine don't have to.
#
# Tests: none (how?)
# ----------------------------------------------------------------------
sub readline {
    my ($self, $prompt) = @_;
    return $self->term->readline($prompt);
}

# ----------------------------------------------------------------------
# print(@data)
#
# This method is here to that subclasses can redirect their output
# stream without having to do silly things like tie STDOUT (although
# they still can if they want, by overriding this method).
#
# Tests: none
# ----------------------------------------------------------------------
sub print {
    my ($self, @stuff) = @_;
    my $OUT = $self->term->Attribs->{'outstream'};

    CORE::print $OUT @stuff;
}

# ----------------------------------------------------------------------
# quit([$status])
#
# Exits the interpreter with $status as the exit status (0 by default).
# If $self->outro() returns a defined value, it is printed here.
#
# Tests: none
# ----------------------------------------------------------------------
sub quit {
    my ($self, $status) = @_;
    $status = 0 unless defined $status;

    my $blurb = $self->outro();
    $self->print("$blurb\n") if defined $blurb;

    if (my $h = $self->histfile) {
        # XXX Can this be better encapsulated?
        $self->term->WriteHistory($h);
    }

    exit($status);
}


# ----------------------------------------------------------------------
# precmd($line)
#
# This is called immediately before parseline(), to give the subclass
# first crack at manipulating the input line.  This might be a good
# place to do, for example, tilde-expansion, or some other kind of
# variable pre-processing.
#
# Tests: t/pre,postcmd.t
# ----------------------------------------------------------------------
sub precmd {
    my ($self, $line) = @_;
    return $line;
}

# ----------------------------------------------------------------------
# postcmd($output)
#
# This is called immediately before $output is passed to print, to
# give the class one last chance to manipulate the text before it is
# sent to the output stream.
#
# Tests: t/pre,postcmd.t
# ----------------------------------------------------------------------
sub postcmd {
    my ($self, $output) = @_;
    return $output;
}

# ----------------------------------------------------------------------
# default($cmd, @args)
#
# What to do by default, i.e., when there is no matching do_foo method.
#
# Tests: t/default.t
# ----------------------------------------------------------------------
sub default {
    my ($self, $cmd, @args) = @_;
    my $class = ref $self || $self;
    return "$class->$cmd(@args) called, but do_$cmd is not defined!";
}

# ----------------------------------------------------------------------
# emptycommand()
#
# What to do when an empty command is issued
# ----------------------------------------------------------------------
sub emptycommand {
    my $self = shift;
    return;
}

# ----------------------------------------------------------------------
# prompt_no()
#
# Returns the command number in the history.
#
# Tests: t/prompt_no.t
# ----------------------------------------------------------------------
sub prompt_no {
    my $self = shift;
    return $self->term->where_history();
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Some general purpose methods.  Subclasses may wish to override some
# of these, but many of them (version, progname) are probably ok as is.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# ----------------------------------------------------------------------
# version()
#
# Returns the version number.
# ----------------------------------------------------------------------
sub version {
    return $VERSION;
}

# ----------------------------------------------------------------------
# do_version()
#
# Example command method.
#
# Tests: t/version.t
# ----------------------------------------------------------------------
sub do_version {
    my $self = shift;
    return sprintf "%s v%s", $self->progname, $self->version;
}

sub help_version {
    return "Display the version."
}

# ----------------------------------------------------------------------
# progname()
#
# Returns the name of the program in question.  Defaults to
# basename($0) or the classname of the caller.
#
# Tests: t/progname.t
# ----------------------------------------------------------------------
sub progname {
    my $self = shift;
    return basename($0) || ref $self || $self;
}

# ----------------------------------------------------------------------
# intro()
#
# Introduction text, printed when the interpreter starts up.  The
# default is to print the GPL-recommended introduction.  I would 
# hope that modules that utilize Shell::Base would create intro()
# methods that incorporate this, if possible:
#
#   sub intro {
#       my $self = shift;
#       my $default_intro = $self->SUPER::intro();
#
#       return "My Intro\n$default_intro";
#   }
#
# Tests: t/intro.t
# ----------------------------------------------------------------------
sub intro {
    # No default intro
    return ""
}

# ----------------------------------------------------------------------
# outro()
#
# Similar to intro(), but called from within quit(), immediately
# before exit is called.
#
# Tests: t/outro.t
# ----------------------------------------------------------------------
sub outro {
    my $self = shift;
    return sprintf "Thanks for using %s!", $self->progname;
}

# ----------------------------------------------------------------------
# parseline($line)
#
# parseline splits a line into three components:
#
#    1. Command
#
#    2. Environment variable additions
#
#    3. Arguments
#
# returns an array that looks like:
#
#   ($cmd, \%env, @args)
#
# %env comes from environment variable assignments that occur at
# the beginning of the line:
#
#   FOO=bar cmd opt1 opt2
#
# In this case $env{FOO} = "bar".
#
# This parseline method doesn't handle pipelines gracefully; pipes
# ill treated like any other token.
#
# Tests: t/parseline.t
# ----------------------------------------------------------------------
sub parseline {
    my ($self, $line) = @_;
    my ($cmd, %env, @args);

    @args = shellwords($line);
    %env = ();

    while (@args) {
        if ($args[0] =~ /=/) {
            my ($n, $v) = split /=/, shift(@args), 2;
            $env{$n} = $v || "";
        }
        else {
            $cmd = shift @args;
            last;
        }
    }

    return (($cmd or ""), \%env, @args);
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Generic accessors
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# ----------------------------------------------------------------------
# args([$arg])
#
# Returns the hash ref of configuration arguments.  If passed a single
# value, then that configuration value will be returned.
#
# Tests: t/args.t
# ----------------------------------------------------------------------
sub args {
    my $self = shift;
    if (@_) {
        return $self->{ ARGS }->{ $_[0] }
            || $self->{ ARGS }->{ uc $_[0] };
    }
    return $self->{ ARGS };
}

# ----------------------------------------------------------------------
# config([$arg])
#
# Returns the hash reference of configuration parameters read from
# the rc file(s).
#
# Tests: t/init_rcfiles.t
# ----------------------------------------------------------------------
sub config {
    my $self = shift;
    if (@_) {
        return $self->{ CONFIG }->{ $_[0] };
    }
    return $self->{ CONFIG };
}


# ----------------------------------------------------------------------
# term()
#
# Returns the Term::ReadLine instance.  Useful if the subclass needs
# do something like modify attributes on the instance.
#
# Tests: t/term.t
# ----------------------------------------------------------------------
sub term {
    my $self = shift;
    $self->{ TERM } = shift if (@_);
    return $self->{ TERM };
}

# ----------------------------------------------------------------------
# histfile([$histfile])
#
# Gets/set the history file.
#
# Tests: t/histfile.t
# ----------------------------------------------------------------------
sub histfile {
    my $self = shift;
    $self->{ HISTFILE } = shift if (@_);
    return $self->{ HISTFILE };
}


# ----------------------------------------------------------------------
# prompt([$prompt[, @args]])
#
# The prompt can be modified using this method.  For example, multiline
# commands (which much be handled by the subclass) might modify the
# prompt, e.g., PS1 and PS2 in bash.  If $prompt is a coderef, it is
# executed with $self and @args:
#
#   $self->{ PROMPT } = &$prompt($self, @args);
#
# Tests: t/prompt.t
# ----------------------------------------------------------------------
sub prompt {
    my $self = shift;
    if (@_) {
        my $p = shift;
        if (ref($p) eq 'CODE') {
            $self->{ PROMPT } = &$p($self, @_);
        }
        else {
            $self->{ PROMPT } = $p;
        }
    }
    return $self->{ PROMPT };
}

# ----------------------------------------------------------------------
# pager([$pager])
#
# It is possible that each time through the loop in run() might need
# to be passed through a pager; this method exists to figure out what
# that pager should be.
#
# Tests: t/pager.t
# ----------------------------------------------------------------------
sub pager {
    my $self = shift;

    if (@_) {
        $self->{ PAGER } = shift;
    }

    unless (defined $self->{ PAGER }) {
        $self->{ PAGER } = $PAGER || "less";
        $self->{ PAGER } = "more" unless -x $self->{ PAGER };
    }

    return $self->{ PAGER };
}


# ----------------------------------------------------------------------
# help([$topic[, @args]])
#
# Displays help. With $topic, it attempts to call $self->help_$topic,
# which is expected to return a string.  Without $topic, it lists the
# available help topics, which is a list of methods that begin with
# help_; these names are massaged with s/^help_// before being displayed.
# ----------------------------------------------------------------------
sub help {
    my ($self, $topic, @args) = @_;
    my @ret;

    if ($topic) {
        if (my $sub = $self->can("help_$topic")) {
            push @ret,  $self->$sub(@_);
        }
        else {
            push @ret,
                "Sorry, no help available for `$topic'.";
        }
    }

    else {
        my @helps = $self->helps;
        if (@helps) {
            push @ret, 
                "Help is available for the following topics:",
                "===========================================",
                map({ "  * $_" } @helps),
                "===========================================";
        }
        else {
            my $me = $self->progname;
            push @ret, "No help available for $me.",
                    "Please complain to the author!";
        }
    }

    return join "\n", @ret;
}


# ----------------------------------------------------------------------
# helps([@helps])
#
# Returns or sets a list of possible help functions.
# ----------------------------------------------------------------------
sub helps {
    my $self = shift;

    if (@_) {
        $self->{ HELPS } = \@_;
    }

    return @{ $self->{ HELPS } };
}

# ----------------------------------------------------------------------
# complete(@_)
#
# Command completion -- this method is designed to be assigned as:
#
#   $term->Attribs->{completion_function} = sub { $self->complete(@_) };
# 
# Note the silly setup -- it will be called as a function, without
# any references to $self, so we need to force $self into the equation
# using a closure.
# ----------------------------------------------------------------------
sub complete {
    my ($self, $word, $line, $pos) = @_;
    #warn "Completing '$word' in '$line' (pos $pos)";

    # This is grossly suboptimal, and only completes on
    # defined keywords.  A better idea is to:
    #  1. If subtr($line, ' ') is less than $pos,
    #     then we are completing a command
    #     (the current method does this correctly)
    #  2. Otherwise, we are completing something else.
    #     By default, this should defer to regular filename
    #     completion.
    return grep { /$word/ } $self->completions;
}

sub completions {
    my $self = shift;

    if (@_) {
        $self->{ COMPLETIONS } = \@_;
    }

    return @{ $self->{ COMPLETIONS } };
}

# ----------------------------------------------------------------------
# _do_shell
#
# An example do_shell method.  This can be used in subclasses like:
# sub do_shell { shift->_do_shell(@_) }
# ----------------------------------------------------------------------
sub _do_shell {
    my ($self, @args) = @_;
    my $sh = $SHELL || '/bin/sh';

    unless (system($sh, @args) == 0) {
        carp "Problem executing $sh: $!";
    }

    # No return value!
    return;
}

# ----------------------------------------------------------------------
# An example predefined command: warranty.  This also,
# incidentally, fulfills the GPL recommended requirements.
# ----------------------------------------------------------------------
sub do_warranty {
    my $self = shift;

    require Text::Wrap;
    # To prevent "used only once" warnings.
    local $Text::Wrap::columns =
          $Text::Wrap::columns = $COLUMNS || '72';

    return Text::Wrap::wrap('', '', sprintf
'Because %s is licensed free of charge, there is no warranty for the ' .
'program, to the extent permitted by applicable law.  Except when ' .
'otherwise stated in writing the copyright holders and/or other parties ' .
'provide the program "as is" without warranty of any kind, either ' .
'expressed or implied, including, but not limited to, the implied ' .
'warranties of merchantability and fitness for a particular purpose. ' .
'The entire risk as to the quality and performance of the program is ' .
'with you.  Should the program prove defective, you assume the cost of ' .
'all necessary servicing, repair or correction.', $self->progname);
}

# Helper function
sub _merge_hash {
    my ($merge_to, $merge_from) = @_;
    $merge_to->{$_} = $merge_from->{$_}
        for keys %$merge_from;
}

__END__

=head1 NAME

Shell::Base - A generic class to build line-oriented command interpreters.

=head1 SYNOPSIS

  package My::Shell;

  use Shell::Base;
  use base qw(Shell::Base);

  sub do_greeting {
      return "Hello!"
  }

=head1 DESCRIPTION

Shell::Base is a base class designed for building command line
programs.  It defines a number of useful defaults, simplifies adding
commands and help, and integrates well with Term::ReadLine.

After writing several REP (Read-Eval-Print) loops in Perl, I found
myself wishing for something a little more convenient than starting
with:

  while(1) {
      my $line = <STDIN>;
      last unless defined $line;

      chomp $line;
      if ($line =~ /^...

=head2 Features

Shell::Base provides simple access to many of the things I always
write into my REP's, as well as support for many thing that I always
intend to, but never find time for:

=over 4

=item readline support

Shell::Base provides simple access to the readline library via
Term::ReadLine, including built-in tab-completion and easy integration
with the history file features.

If a subclass does want or need Term::ReadLine support, then it can be
replaced in subclasses by overriding a few methods.  See L<"Using
Shell::Base Without readline">, below.

=item Trivial to add commands

Adding commands to your shell is as simple as creating methods: the
command C<foo> is dispatched to C<do_foo>. In addition, there are
hooks for unknown commands and for when the user just hits
E<lt>ReturnE<gt>, both of which a subclass can override.

=item Integrated help system

Shell::Base makes it simple to integrate online help within alongside
your command methods.  Help for a command C<foo> can be retrieved with
C<help foo>, with the addition of one method.  In addition, a general
C<help> command lists all possible help commands; this list is
generated at run time, so there's no possibility of forgetting to add
help methods to the list of available topics.

=item Pager integration

Output can be sent through the user's default pager (as defined by
$ENV{'PAGER'}, with a reasonable default) or dumped directly to
STDOUT.

=item Customizable output stream(s)

Printing is handled through a print() method, which can be overridden
in a subclass to send output anywhere.

=item Pre- and post-processing methods

Input received from readline() can be processed before it is
parsed, and output from command methods can be post-processed before
it is sent to print().

=item Automatic support for RC files

A simple RC-file parser is built in, which handles name = value type
configuration files.  This parser handles comments, whitespace,
multiline definitions, boolean and (name, value) option types, and
multiple files (e.g., F</etc/foorc>, F<$HOME/.foorc>).

=back

Shell::Base was originally based, conceptually, on Python's C<cmd.Cmd>
class, though it has expanded far beyond what C<Cmd> offers.

=head1 METHODS

There are two basic types of methods:  methods that control how a
Shell::Base-derived object behaves, and methods that add command to
the shell.

All aspects of a Shell::Base-derived object are available via
accessors, from the Term::ReadLine instance to data members, to make
life easier for subclass implementors.

I<NB:> The following list isn't really in any order!

=over 4

=item new

The constructor is called C<new>, and should be inherited from
Shell::Base (and not overridden).  C<new> should be called with a
reference to a hash of name => value parameters:

  my %options = (HISTFILE => glob("~/.myshell_history"),
                 OPTION_1 => $one,
                 OPTION_2 => $two);

  my $shell = My::Shell->new(\%options);

C<new> calls a number of initializing methods, each of which will be
called with a reference to the passed in hash of parameters as the
only argument:

=over

=item init_rl(\%args)

C<init_rl> initializes the Term::ReadLine instance.  If a subclass
does not intend to use Term::ReadLine, this method can be overridden.
(There are other methods that need to be overridden to eliminate
readline completely; see L<"Using Shell::Base Without readline"> for
more details.)

The completion method, C<complete>, is set here, though the list of
possible completions is generated in the C<init_completions> method.

If a HISTFILE parameter is passed to C<init_rl>, then the internal
Term::ReadLine instance will attempt to use that file for history
functions.  See L<Term::ReadLine::Gnu/"History Functions"> for more
details.

=item init_rcfiles(\%args)

C<init_rcfiles> treats each element in the RCFILES array (passed into
the contructor) as a configuration file, and attempts to read and
parse it.  See L<"RC Files">, below.

=item init_help(\%args)

C<init_help> generates the list of available help topics, which is all
methods that match the pattern C<^help_>, by default.  Once this list
is generated, it is stored using the C<helps> method (see L<"helps">).

=item init_completions(\%args)

C<init_completions> creates the list of methods that are
tab-completable, and sets them using the C<completions> method.  By
default, it finds all methods that begin with C<^do_> in the current
class and superclass(es).

The default completion method, C<complete>, chooses completions from
this list based on the line and word being completed.  See
L<"complete">.

=item init(\%args)

A general purpose C<init> method, designed to be overridden by
subclasses.  The default C<init> method in Shell::Base does nothing.

In general, subclass-specific initializations should go in this
method.

=back

A subclass's C<init> method should be carful about deleting from the
hash that they get as a parameter -- items removed from the hash are
really gone.  At the same time, items can be added to the hash, and
will persist.  The original parameters can be retrieved at run time
using the C<args> method.

Similarly, configuration data parsed from RCFILES can be retrieved
using the C<config> method.

=item run

The main "loop" of the program is a method called C<run> -- all other
methods are called in preparation for the call to C<run>, or are
called from within C<run>.  C<run> takes no parameters, and does not
return.

  $shell = My::Shell->new();
  $shell->run();

At the top of the loop, C<run> prints the value of $self->intro, if it
is defined:

  my $intro = $self->intro();
  $self->print("$intro\n")
      if defined $intro;

C<run> does several things for each iteration of the REP loop that are
worth noting:

=over 4

=item *

Reads a line of input using $self->readline(), passing the value of
$self->prompt():

  $line = $self->readline($self->prompt);

=item *

Passes that line through $self->precmd(), for possible manipulation:

  $line = $self->precmd($line);

=item *

Parses the line:

  ($cmd, $env, @args) = $self->parseline($line);

See L<"parseline"> for details about C<parseline>, and what $cmd,
$env, and @args are.

=item *

Update environment variables with entries from %$env, for the command
$cmd only.

=item *

Checks the contents of $cmd; there are a few special cases:

=over 4

=item *

If $cmd matches $Shell::Base::RE_QUIT, the method C<quit>
is invoked:

  $output = $self->quit();

$RE_QUIT is C<^(?i)\s*(quit|exit|logout)> by default

=item *

Otherwise, if $cmd matches $Shell::Base::RE_HELP, the method C<help>
is invoked, with @args as parameters:

  $output = $self->help(@args);

$RE_HELP is C<^(?i)\s*(help|\?)> by default.

=item *

Otherwise, if $cmd matches $Shell::Base::RE_SHEBANG, the method
C<do_shell> is invoked, with @args as parameters:

  $output = $self->do_shell(@args);

$RE_SHEBANG is C<^\s*!\s*$> by default.

=item *

Otherwise, the command C<do_$cmd> is invoked, with @args as
parameters:

  my $method = "do_$cmd";
  $output = $self->$method(@args);

=back

=item *

$output is passed to $self->postcmd() for postprocessing:

  $output = $self->postcmd($output);

=item *

Finally, if $output is not C<undef>, it is passed to $self->print(),
with a newline appended:

  $self->print("$output\n")
      if defined $output;

=back

When the main loop ends, usually through the C<exit> or C<quit>
commands, or when the user issues CTRL-D, C<run> calls the C<quit>
method.

=item args([$what])

The original hash of arguments passed into the constructor is stored
in the instance, and can be retrieved using the args method, which is
an accessor only (though the hash returned by C<args> is live, and
changes will propogate).

If C<args> is passed a value, then the value associated with that key
will be returned.  An example:

  my $shell = My::Shell->new(FOO => "foo", BAR => "bar");

  my $foo = $shell->args("FOO");  # $foo contains "foo"
  my $bar = $shell->args("BAR");  # $bar contains "bar"
  my $baz = $shell->args("BAZ");  # $baz is undefined
  my $args = $shell->args();      # $args is a ref to the whole hash

As a convenience, if a specified argument is not found, it is
uppercased, and then tried again, so:

  my $foo = $shell->args("FOO");

and 

  my $foo = $shell->args("foo");

are identical if there is a C<FOO> arg and no C<foo> arg.

=item config([$what])

Configuration data gleaned from RCFILES can be retrieved using the
C<config> method.  C<config> behaves similarly to the C<args> method.

=item helps

When called without arguments, C<helps> returns a list of all the
available help_foo methods, as a list.

When called with arguments, C<helps> uses these arguments to set the
current list of help methods.

This is the method called by C<init_help> to fill in the list of
available help methods, and C<help> when it needs to figure out the
available help topics.

=item completions

Similar to C<helps>, except that completions returns or sets the list
of completions possible when the user hits E<lt>tabE<gt>.

=item print

The C<print> method, well, prints its data.  C<print> is a method so
that subclasses can override it; here is a small example class,
C<Tied::Shell>, that wraps around a Tie::File instance, in which all
data is printed to the Tie::File instance, as well as to the normal
place.  This makes it ideal for (e.g.) logging sessions:

  package Tied::Shell;

  use Shell::Base;
  use Tie::File;

  use strict;
  use base qw(Shell::Base);

  sub init {
      my ($self, $args) = @_;
      my @file;

      tie @file, 'Tie::File', $args->{ FILENAME };

      $self->{ TIEFILE } = \@file;
  }

  # Append to self, then call SUPER::print
  sub print {
      my ($self, @lines) = @_;
      push @{ $self->{ TIEFILE } }, @lines;

      return $self->SUPER::print(@lines);
  }

  sub quit {
      my $self = shift;
      untie @{ $self->{ TIEFILE } };
      $self->SUPER::quit(@_);
  }

(See L<Tie::File> for the appropriate details.)

=item readline

The C<readline> method is a wrapper for $self->term->readline; it is
called at the top of the REP loop within C<run> to get the next line
of input.  C<readline> is it's own method so that subclasses which do
not use Term::ReadLine can override it specifically.  A very basic,
non-readline C<readline> could look like:

  sub readline {
      my ($self, $prompt) = @_;
      my $line;

      print $prompt;
      chomp($line = <STDIN>);

      return $line;
  }

As implied by the example, C<readline> will be passed the prompt to be
displayed, which should be a string (it will be treated like one).

A good example of when this might be overridden would be on systems
that prefer to use C<editline> instead of GNU readline, using the
C<Term::EditLine> module (e.g., NetBSD):

  # Initialize Term::EditLine
  sub init_rl {
      my ($self, $args) = @_;

      require Term::EditLine;
      $self->{ TERM } = Term::EditLine->new(ref $self);

      return $self;
  }

  # Return the Term::EditLine instance
  sub term {
      my $self = shift;
      return $self->{ TERM };
  }

  # Get a line of input
  sub readline {
      my ($self, $prompt) = @_;
      my $line;
      my $term = $self->term;

      $term->set_prompt($prompt);
      $line = $term->gets();
      $term->history_enter($line);

      return $line;
  }

=item default

When an unknown command is received, the C<default> method is invoked,
with ($cmd, @args) as the arguments.  The default C<default> method
simply returns an error string, but this can of course be overridden
in a subclass:

  sub default {
      my ($self, @cmd) = @_;
      my $output = `@cmd`;
      chomp $output;  # everything is printed with an extra "\n"
      return $output;
  }

=item precmd 

C<precmd> is called after a line of input is read, but before it is
parsed.  C<precmd> will be called with $line as the sole argument, and
it is expected to return a string suitable for splitting with
C<parseline>.  Any amount of massaging can be done to $line, of
course.

The default C<precmd> method does nothing:

  sub precmd {
      my ($self, $line) = @_;
      return $line;
  }

This would be a good place to handle things tilde-expansion:

  sub precmd {
      my ($self, $line) = @_;
      $line =~ s{~([\w\d_-]*)}
                { $1 ? (getpwnam($1))[7] : $ENV{HOME} }e;
      return $line;
  }

=item postcmd

C<postcmd> is called immediately before any output is printed.
C<postcmd> will be passed a scalar containing the output of whatever
command C<run> invoked.  C<postcmd> is expected to return a string
suitable for printing; if the return of C<postcmd> is undef, then
nothing will be printed.

The default C<postcmd> method does nothing:

  sub postcmd {
      my ($self, $output) = @_;
      return $output;
  }

You can do fun output filtering here:

  use Text::Bastardize;
  my $bastard = Text::Bastardize->new;
  sub postcmd {
      my ($self, $output) = @_;

      $bastard->charge($output);

      return $bastard->k3wlt0k()
  }

Or translation:

  use Text::Iconv;
  my $converter;
  sub postcmd {
      my ($self, $output) = @_;

      unless (defined $converter) {
          # Read these values from the config files
          my $from_lang = $self->config("from_lang");
          my $to_lang = $self->config("to_lang");

          $converter = Text::Iconv->new($from_lang, $to_lang);

          # Return undef on error, don't croak
          $converter->raise_error(0);
      }

      # Fall back to unconverted output, not croak
      return $completer->convert($output) || $output;
  }

Or put the tildes back in:

  sub postcmd {
      my ($self, $line) = @_;
      $line =~ s{(/home/([^/ ]+))}
                { -d $1 ? "~$2" : $1 }ge;
      return $line;
  }

=item pager

The C<pager> method attempts to determine what the user's preferred
pager is, and return it.  This can be used within an overridden
C<print> method, for example, to send everything through a pager:

  sub print {
      my ($self, @stuff) = @_;
      my $pager = $self->pager;

      open my $P, "|$pager" or carp "Can't open $pager: $!";
      CORE::print $P @stuff;
      close $P;
  }

Note the explicit use of CORE::print, to prevent infinite recursion.

=item parseline

A line is divided into ($command, %env, @args) using
$self->parseline(). A command C<foo> is dispatched to a method
C<do_foo>, with @args passed as an array, and with %ENV updated to
include %env.

If there is no C<do_foo> method for a command C<foo>, then the method
C<default> will be called.  Subclasses can override the C<default>
method.

%ENV is localized and updated with the contents of %env for the
current command.  %env is populated in a similar fashion to how
F</bin/sh> does; the command:

    FOO=bar baz

Invokes the C<do_baz> method with $ENV{'FOO'} = "bar".

Shell::Base doesn't (currently) do anything interesting with
pipelines; the command:

  foo | bar

will be parsed by parseline() as:
  
  ("foo", {}, "|", "bar")

rather than as two separate connected commands.  Support for pipelines
in on the TODO list.

=item prompt

Gets or sets the current prompt.  The default prompt is:

  sprintf "(%s) \$ ", __PACKAGE__;

The prompt method can be overridden, of course, possibly using
something like C<String::Format>:

  use Cwd;
  use File::Basename qw(basename);
  use Net::Domain qw(hostfqdn);
  use String::Format qw(stringf);
  use Sys::Hostname qw(hostname);

  sub prompt {
      my $self = shift;
      my $fmt = $self->{ PROMPT_FMT };
      return stringf $fmt => {
          '$' => $$,
          'w' => cwd,
          'W' => basename(cwd),
          '0' => $self->progname,
          '!' => $self->prompt_no,
          'u' => scalar getpwuid($<),
          'g' => scalar getgrgid($(),
          'c' => ref($self),
          'h' => hostname,
          'H' => hostfqdn,
      };
  }

Then $self->{ PROMPT_FMT } can be set to, for example, C<%u@%h %w %%>,
which might yield a prompt like:

  darren@tumbleweed /tmp/Shell-Base %

(See L<String::Format> for the appropriate details.)

The value passed to C<prompt> can be a code ref; if so, it is invoked
with $self and any additional arguments passed to C<prompt> as the
arguments:

    $self->prompt(\&func, @stuff);

Will call:

    &$func($self, @stuff);

and use the return value as the prompt string.

=item intro / outro

Text that is displayed when control enters C<run> (C<intro>) and
C<quit> (C<outro>).  If the method returns a non-undef result, it will
be passed to $self->print().

=item quit

The C<quit> method currently handles closing the history file; if it
is overridden, $self->SUPER::quit() should be called, so that the
history file will be written out.

The results of $self->outro() will be passed to $self->print() as
well.

=back

=head2 Methods That Add Commands

Any command that run() doesn't recognize will be treated as a command;
a method named C<do_$command> will be invoked, in an eval block.
Remember that a line is parsed into ($command, %env, @args);
C<do_$command> will be invoked with @args as @_, and %ENV updated to
include the contents of %env.  The effect is similar to:

  my ($command, $env, @args) = $self->parseline($line);
  my $method = "do_$command";
  local %ENV = (%ENV, %$env);

  my $output = $self->$method(@args);

$output will be passed to $self->print() if it is defined.

Here is method that implements the C<env> command:

  sub do_env {
      my ($self, @args) = @_;
      my @output;

      for (keys %ENV) {
          push @output, "$_=$ENV{$_}";
      }

      return join "\n", @output;
  }

And here is an C<rm> command:

  sub do_rm {
      my ($self, @files) = @_;
      my ($file, @errors);

      for $file (@files) {
          unlink $file
              or push @errors, $file;
      }

      if (@errors) {
          return "Couldn't delete " . join ", ", @errors;
      }

      return;
  }

=head1 MISCELLANEOUS

=head2 Quick Imports

If Shell::Base, or any Shell::Base subclass that does not does
implement an C<import> method, is invoked as:

  use My::Shell qw(shell);

a function named C<shell> is installed in the calling package.  This
C<shell> function is very simple, and turns this:

  shell(%args);

into this:

  My::Shell->new(%args)->run();

This is most useful for one-liners:

  $ perl -MMy::Shell=shell -e shell

=head2 RC Files

The rcfile parser is simple, and parses (name, value) tuples from
config files, according to these rules:

=over 4

=item Definitions

Most definitions are in name = value format:

  foo = bar
  baz = quux

Boolean defitions in the form

  wiffle

are allowed, and define C<wiffle> as 1.  Any definition without an =
is considered a boolean definition.  Boolean definitions in the form
C<I<no>wiffle> define C<wiffle> as 0:

  nowiffle

=item Comments

Everything after a # is considered a comment, and is stripped from
the line immediately

=item Whitespace

Whitespace is (mostly) ignored.  The following are equivalent:

  foo=bar
  foo    =    bar

Whitespace after the beginning of the value is I<not> ignored:

  foo =    bar baz  quux

C<foo> contains C<bar baz  quux>.

=item Line continuations

Lines ending with \ are continued on the next line:

  form_letter = Dear %s,\
  How are you today? \
  Love, \
  %s
  
=back

=head2 Using Shell::Base Without readline

The appropriate methods to override in this case are:

=over 4

=item init_rl

The readline initialization method.

=item term

Returns the Term::ReadLine instance; primarily used by the other methods
listed in this section.

=item readline

Returns the next line of input.  Will be passed 1 argument, the
prompt to display.  See L<"readline"> for an example of overriding
C<readline>.

=item print

Called with the data to be printed.  By default, this method prints
to $self->term->OUT, but subclasses that aren't using Term::ReadLine
will want to provide a useful alternative.  One possibily might be:

  sub print {
      my ($self, @print_me) = @_;
      CORE::print(@print_me);
  }

Another good example was given above, in L<"pager">:

  sub print {
      my ($self, @stuff) = @_;
      my $pager = $self->pager;

      open my $P, "|$pager" or carp "Can't open $pager: $!";
      CORE::print $P @stuff;
      close $P;
  }

=back

=head1 NOTES

Some parts of this API will likely change in the future.  In an
upcoming version, C<do_$foo> methods will mostly likely be expected to
return a ($status, $output) pair rather than simply $output.  Any API
changes that are likely to break existing applications will be noted.

=head1 TODO

=over 4

=item abbreviations

Add abbreviation support, by default via Text::Abbrev, but
overriddable, so that a shell can have (for example), \x type
commands, or /x type commands.  This can currently be done by
overriding the precmd() method or parseline() methods; for example,
this parseline() method strips a leading C</>, for IRC-like commands
(C</foo>, C</bar>)

  sub parseline {
      my ($self, $line) = @_;
      my ($cmd, $env, @args) = $self->SUPER::parseline($line);

      $cmd =~ s:^/::;
      return ($cmd, $env, @args);
  }

Another way to implement abbreviations would be to override the
C<complete> method.

=item command pipelines

I have some ideas about how to implement pipelines, but, since I have
yet to look at the code in any existing shells, I might be completely
insane and totally on the wrong track.  I therefore reserve the right
to not implement this feature now, until I've looked at how some
proper shells implement pipelines.

=back

=head1 AUTHOR

darren chamberlain E<lt>darren@cpan.orgE<gt>

=head1 REVISION

This documentation describes C<Shell::Base>, $Revision: 1.5 $.

=head1 COPYRIGHT

Copyright (C) 2003 darren chamberlain.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

