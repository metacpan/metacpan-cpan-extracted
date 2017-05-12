# Term::ShellUI.pm
# Scott Bronson
# 3 Nov 2003
# Covered by the MIT license.

# Makes it very easy to implement a GDB-like interface.

package Term::ShellUI;

use strict;

use Term::ReadLine ();
use Text::Shellwords::Cursor;

use vars qw($VERSION);
$VERSION = '0.92';


=head1 NAME

Term::ShellUI - A fully-featured shell-like command line environment

=head1 SYNOPSIS

  use Term::ShellUI;
  my $term = new Term::ShellUI(
      commands => {
              "cd" => {
                  desc => "Change to directory DIR",
                  maxargs => 1, args => sub { shift->complete_onlydirs(@_); },
                  proc => sub { chdir($_[0] || $ENV{HOME} || $ENV{LOGDIR}); },
              },
              "chdir" => { alias => 'cd' },
              "pwd" => {
                  desc => "Print the current working directory",
                  maxargs => 0, proc => sub { system('pwd'); },
              },
              "quit" => {
                  desc => "Quit this program", maxargs => 0,
                  method => sub { shift->exit_requested(1); },
              }},
          history_file => '~/.shellui-synopsis-history',
      );
  print 'Using '.$term->{term}->ReadLine."\n";
  $term->run();

=head1 DESCRIPTION

Term::ShellUI uses the history and autocompletion features of L<Term::ReadLine>
to present a sophisticated command-line interface to the user.  It tries to
make every feature that one would expect to see in a fully interactive shell
trivial to implement.
You simply declare your command set and let ShellUI take
care of the heavy lifting.

This module was previously called L<Term::GDBUI>.

=head1 COMMAND SET

A command set is the data structure that
describes your application's entire user interface.
It's easiest to illustrate with a working example.
We shall implement the following 6 L</COMMAND>s:

=over 4

=item help

Prints the help for the given command.
With no arguments, prints a list and short summary of all available commands.

=item h

This is just a synonym for "help".  We don't want to list it in the
possible completions.
Of course, pressing "h<tab><return>" will autocomplete to "help" and
then execute the help command.  Including this command allows you to
simply type "h<return>".

The 'alias' directive used to be called 'syn' (for synonym).
Either term works.

=item exists

This command shows how to use the
L</complete_files>
routines to complete on file names,
and how to provide more comprehensive help.

=item show

Demonstrates subcommands (like GDB's show command).
This makes it easy to implement commands like "show warranty"
and "show args".

=item show args

This shows more advanced argument processing.
First, it uses cusom argument completion: a static completion for the
first argument (either "create" or "delete") and the standard
file completion for the second.  When executed, it echoes its own command
name followed by its arguments.

=item quit

How to nicely quit.
Term::ShellUI also follows Term::ReadLine's default of quitting
when Control-D is pressed.

=back

This code is fairly comprehensive because it attempts to
demonstrate most of Term::ShellUI's many features.  You can find a working
version of this exact code titled "synopsis" in the examples directory.
For a more real-world example, see the fileman-example in the same
directory.

 sub get_commands
 {
     return {
         "help" => {
             desc => "Print helpful information",
             args => sub { shift->help_args(undef, @_); },
             method => sub { shift->help_call(undef, @_); }
         },
         "h" =>      { alias => "help", exclude_from_completion=>1},
         "exists" => {
             desc => "List whether files exist",
             args => sub { shift->complete_files(@_); },
             proc => sub {
                 print "exists: " .
                     join(", ", map {-e($_) ? "<$_>":$_} @_) .
                     "\n";
             },
             doc => <<EOL,
 Comprehensive documentation for our ls command.
 If a file exists, it is printed in <angle brackets>.
 The help can\nspan\nmany\nlines
 EOL
         },
         "show" => {
             desc => "An example of using subcommands",
             cmds => {
                 "warranty" => { proc => "You have no warranty!\n" },
                 "args" => {
                     minargs => 2, maxargs => 2,
                     args => [ sub {qw(create delete)},
                               \&Term::ShellUI::complete_files ],
                     desc => "Demonstrate method calling",
                     method => sub {
                         my $self = shift;
                         my $parms = shift;
                         print $self->get_cname($parms->{cname}) .
                             ": " . join(" ",@_), "\n";
                     },
                 },
             },
         },
         "quit" => {
             desc => "Quit using Fileman",
             maxargs => 0,
             method => sub { shift->exit_requested(1); }
         },
         "q" => { alias => 'quit', exclude_from_completion => 1 },
     };
 }


=head1 COMMAND

This data structure describes a single command implemented
by your application.
"help", "exit", etc.
All fields are optional.
Commands are passed to Term::ShellUI using a L</COMMAND SET>.

=over 4

=item desc

A short, one-line description for the command.  Normally this is
a simple string, but it may also be a subroutine that
will be called every time the description is printed.
The subroutine takes two arguments, $self (the Term::ShellUI object),
and $cmd (the command hash for the command), and returns the
command's description as a string.

=item doc

A comprehensive, many-line description for the command.
Like desc, this is normally a string but
if you store a reference to a subroutine in this field,
it will be called to calculate the documentation.
Your subroutine should accept three arguments: self (the Term::ShellUI object),
cmd (the command hash for the command), and the command's name.
It should return a string containing the command's documentation.
See examples/xmlexer to see how to read the doc
for a command out of the pod.

=item minargs

=item maxargs

These set the minimum and maximum number of arguments that this
command will accept.

=item proc

This contains a reference to the subroutine that should be executed
when this command is called.  Arguments are those passed on the
command line and the return value is the value returned by
call_cmd and process_a_cmd (i.e. it is ignored unless your
application makes use of it).

If this field is a string instead of a subroutine ref, the string
is printed when the command is executed (good for things like
"Not implemented yet").
Examples of both subroutine and string procs can be seen in the example
above.

=item method

Similar to proc, but passes more arguments.  Where proc simply passes
the arguments for the command, method also passes the Term::ShellUI object
and the command's parms object (see L</call_cmd>
for more on parms).  Most commands can be implemented entirely using
a simple proc procedure, but sometimes they require addtional information
supplied to the method.  Like proc, method may also be a string.

=item args

This tells how to complete the command's arguments.  It is usually
a subroutine.  See L</complete_files> for an reasonably simple
example, and the L</complete> routine for a description of the
arguments and cmpl data structure.

Args can also be an arrayref.  Each position in the array will be
used as the corresponding argument.
See "show args" in get_commands above for an example.
The last argument is repeated indefinitely (see L</maxargs>
for how to limit this).

Finally, args can also be a string.  The string is intended to
be a reminder and is printed whenever the user types tab twice
(i.e. "a number between 0 and 65536").
It does not affect completion at all.

=item cmds

Command sets can be recursive.  This allows a command to have
subcommands (like GDB's info and show commands, and the
show command in the example above).
A command that has subcommands should only have two fields:
cmds (of course), and desc (briefly describe this collection of subcommands).
It may also implement doc, but ShellUI's default behavior of printing
a summary of the command's subcommands is usually sufficient.
Any other fields (args, method, maxargs, etc) will be taken from
the subcommand.

=item exclude_from_completion

If this field exists, then the command will be excluded from command-line
completion.  This is useful for one-letter abbreviations, such as
"h"->"help": including "h" in the completions just clutters up
the screen.

=item exclude_from_history

If this field exists, the command will never be stored in history.
This is useful for commands like help and quit.

=back

=head2 Default Command

If your command set includes a command named '' (the empty
string), this pseudo-command will be called any time the actual
command cannot be found.  Here's an example:

  '' => {
    proc => "HA ha.  No command here by that name\n",
    desc => "HA ha.  No help for unknown commands.",
    doc => "Yet more taunting...\n",
  },

Note that minargs and maxargs for the default command are ignored.
method and proc will be called no matter how many arguments the user
entered.


=head1 CATEGORIES

Normally, when the user types 'help', she receives a short
summary of all the commands in the command set.
However, if your application has 30 or more commands, this can
result in information overload.  To manage this, you can organize
your commands into help categories

All help categories are assembled into a hash and passed to the
the default L<help_call> and
L</help_args> methods.  If you don't
want to use help categories, simply pass undef for the categories.

Here is an example of how to declare a collection of help categories:

  my $helpcats = {
      breakpoints => {
          desc => "Commands to halt the program",
          cmds => qw(break tbreak delete disable enable),
      },
      data => {
          desc => "Commands to examine data",
          cmds => ['info', 'show warranty', 'show args'],
      }
  };

"show warranty" and "show args" on the last line above
are examples of how to include
subcommands in a help category: separate the command and
subcommands with whitespace.

=head1 CALLBACKS

Callbacks are functions supplied by ShellUI but intended to be called by
your application.
They implement common functions like 'help' and 'history'.

=over 4

=item help_call(cats, parms, topic)

Call this routine to implement your help routine.  Pass
the help categories or undef, followed by the command-line
arguments:

  "help" =>   { desc => "Print helpful information",
                args => sub { shift->help_args($helpcats, @_); },
                method => sub { shift->help_call($helpcats, @_); } },

=cut

sub help_call
{
    my $self = shift;
    my $cats = shift;       # help categories to use
    my $parms = shift;      # data block passed to methods
    my $topic = $_[0];      # topics or commands to get help on

    my $cset = $parms->{cset};
    my $OUT = $self->{OUT};

    if(defined($topic)) {
        if(exists $cats->{$topic}) {
            print $OUT $self->get_category_help($cats->{$topic}, $cset);
        } else {
            print $OUT $self->get_cmd_help(\@_, $cset);
        }
    } elsif(defined($cats)) {
        # no topic -- print a list of the categories
        print $OUT "\nHelp categories:\n\n";
        for(sort keys(%$cats)) {
            print $OUT $self->get_category_summary($_, $cats->{$_});
        }
    } else {
        # no categories -- print a summary of all commands
        print $OUT $self->get_all_cmd_summaries($cset);
    }
}


=item help_args

This provides argument completion for help commands.
See the example above for how to call it.

=cut

sub help_args
{
    my $self = shift;
    my $helpcats = shift;
    my $cmpl = shift;

    my $args = $cmpl->{'args'};
    my $argno = $cmpl->{'argno'};
    my $cset = $cmpl->{'cset'};

    if($argno == 0) {
        # return both categories and commands if we're on the first argument
        return $self->get_cset_completions($cset, keys(%$helpcats));
    }

    my($scset, $scmd, $scname, $sargs) = $self->get_deep_command($cset, $args);

    # without this we'd complete with $scset for all further args
    return [] if $argno >= @$scname;

    return $self->get_cset_completions($scset);
}



=item complete_files

Completes on filesystem objects (files, directories, etc).
Use either

  args => sub { shift->complete_files(@_) },

or

  args => \&complete_files,

Starts in the current directory.

=cut

sub complete_files
{
    my $self = shift;
    my $cmpl = shift;

    $self->suppress_completion_append_character();

    use File::Spec;
    my @path = File::Spec->splitdir($cmpl->{str} || ".");
    my $dir = File::Spec->catdir(@path[0..$#path-1]);

    # eradicate non-matches immediately (this is important if
    # completing in a directory with 3000+ files)
    my $file = $path[$#path];
    $file = '' unless $cmpl->{str};
    my $flen = length($file);

    my @files = ();
    if(opendir(DIR, length($dir) ? $dir : '.')) {
        @files = grep { substr($_,0,$flen) eq $file } readdir DIR;
        closedir DIR;
        # eradicate dotfiles unless user's file begins with a dot
        @files = grep { /^[^.]/ } @files unless $file =~ /^\./;
        # reformat filenames to be exactly as user typed
        @files = map { length($dir) ? ($dir eq '/' ? "/$_" : "$dir/$_") : $_ } @files;
    } else {
        $self->completemsg("Couldn't read dir: $!\n");
    }

    return \@files;
}


=item complete_onlyfiles

Like L</complete_files">
but excludes directories, device nodes, etc.
It returns regular files only.

=cut

sub complete_onlyfiles
{
    my $self = shift;

    # need to do our own escaping because we want to add a space ourselves
    $self->suppress_completion_escape();
    my @c = grep { -f || -d } @{$self->complete_files(@_)};
    $self->{parser}->parse_escape(\@c);
    # append a space if we've completed a unique file
    $c[0] .= (-f($c[0]) ? ' ' : '') if @c == 1;
    # append a helpful slash to indicate directories
    @c = map { -d($_) ? "$_/" : $_ } @c;
    return \@c;
}


=item complete_onlydirs

Like L</complete_files">,
but excludes files, device nodes, etc.
It returns only directories.
It I<does> return the . and .. special directories so you'll need
to remove those manually if you don't want to see them:

  args = sub { grep { !/^\.?\.$/ } complete_onlydirs(@_) },

=cut

sub complete_onlydirs
{
    my $self = shift;
    my @c = grep { -d } @{$self->complete_files(@_)};
    $c[0] .= '/' if @c == 1;    # add a slash if it's a unique match
    return \@c;
}


=item history_call

You can use this callback to implement the standard bash
history command.  This command supports:

    NUM       display last N history items
              (displays all history if N is omitted)
    -c        clear all history
    -d NUM    delete an item from the history

Add it to your command set using something like this:

  "history" => { desc => "Prints the command history",
     doc => "Specify a number to list the last N lines of history" .
            "Pass -c to clear the command history, " .
            "-d NUM to delete a single item\n",
     args => "[-c] [-d] [number]",
     method => sub { shift->history_call(@_) },
  },

=cut

sub history_call
{
    my $self = shift;
    my $parms = shift;
    my $arg = shift;

    # clear history?
    if($arg && $arg eq '-c') {
        $self->{term}->clear_history();
        return;
    }
    if($arg && $arg eq '-d') {
        @_ or die "Need the indexes of the items to delete.\n";
        for(@_) {
            /^\d+$/ or die "'$_' needs to be numeric.\n";
            # function is autoloaded so we can't use can('remove_history')
            # to see if it exists.  So, we'll eval it and pray...
            eval { $self->{term}->remove_history($_); }
        }
        return;
    }

    # number of lines to print (push maximum onto args if no arg supplied)
    my $num = -1;
    if($arg && $arg =~ /^(\d+)$/) {
        $num = $1;
        $arg = undef;
    }
    push @_, $arg if $arg;

    die "Unknown argument" . (@_==1?'':'s') . ": '" .
        join("', '", @_) . "'\n" if @_;

    die "Your readline lib doesn't support history!\n"
        unless $self->{term}->can('GetHistory');

    # argh, this has evolved badly...  seems to work though.
    my @history = $self->{term}->GetHistory();
    my $where = @history;
    $num = @history if $num == -1 || $num > @history;
    @history = @history[@history-$num..$#history];
    $where = $self->{term}->where_history()
        if $self->{term}->can('where_history');
    my $i = $where - @history;
    for(@history) {
        print "$i: $_\n";
        $i += 1;
    }
}


=back

=head1 METHODS

These are the routines that your application calls to create
and use a Term::ShellUI object.
Usually you simply call new() and then run() -- everything else
is handled automatically.
You only need to read this section if you wanted to do something out
of the ordinary.

=over 4

=item new Term::ShellUI(I<C<named args...>>)

Creates a new ShellUI object.

It accepts the following named parameters:

=over 3

=item app

The name of this application (will be passed to L<Term::ReadLine/new>).
Defaults to $0, the name of the current executable.

=item term

Usually Term::ShellUI uses its own Term::ReadLine object
(created with C<new Term::ReadLine $args{'app'}>).  However, if
you can create a new Term::ReadLine object yourself and
supply it using the term argument.

=item blank_repeats_cmd

This tells Term::ShellUI what to do when the user enters a blank
line.  Pass 0 (the default) to have it do nothing (like Bash),
or 1 to have it repeat the last command (like GDB).

=item commands

A hashref containing all the commands that ShellUI will respond to.
The format of this data structure can be found below in the
L<command set|/"COMMAND SET"> documentation.
If you do not supply any commands to the constructor, you must call
the L</commands> method to provide at least a minimal command set before
using many of the following calls.  You may add or delete commands or
even change the entire command set at any time.

=item history_file

If defined then the command history is saved to this file on exit.
It should probably specify a dotfile in the user's home directory.
Tilde expansion is performed, so something like
C<~/.myprog-history> is perfectly acceptable.

=item history_max = 500

This tells how many items to save to the history file.
The default is 500.

Note that this parameter does not affect in-memory history.  Term::ShellUI
makes no attemt to cull history so you're at the mercy
of the default of whatever ReadLine library you are using.
See L<Term::ReadLine::Gnu/StifleHistory> for one way to change this.

=item keep_quotes

Normally all unescaped, unnecessary quote marks are stripped.
If you specify C<keep_quotes=E<gt>1>, however, they are preserved.
This is useful if your application uses quotes to delimit, say,
Perl-style strings.

=item backslash_continues_command

Normally commands don't respect backslash continuation.  If you
pass backslash_continues_command=>1 to L</new>, then whenever a line
ends with a backslash, Term::ShellUI will continue reading.  The backslash
is replaced with a space, so
    $ abc \
    > def

Will produce the command string 'abc  def'.

=item prompt

This is the prompt that should be displayed for every request.
It can be changed at any time using the L</prompt> method.
The default is S<<"$0> ">> (see L<app> above).

If you specify a code reference, then the coderef is executed and
its return value is set as the prompt.  Two arguments are passed
to the coderef: the Term::ShellUI object, and the raw command.
The raw command is always "" unless you're using command completion,
where the raw command is the command line entered so far.

For example, the following
line sets the prompt to "## > " where ## is the current number of history
items.

    $term->prompt(sub { $term->{term}->GetHistory() . " > " });

If you specify an arrayref, then the first item is the normal prompt
and the second item is the prompt when the command is being continued.
For instance, this would emulate Bash's behavior ($ is the normal
prompt, but > is the prompt when continuing).

    $term->prompt(['$', '>']);

Of course, you specify backslash_continues_command=>1 to to L</new> to cause
commands to continue.

And, of course, you can use an array of procs too.

    $term->prompt([sub {'$'}, sub {'<'}]);

=item token_chars

This argument specifies the characters that should be considered
tokens all by themselves.  For instance, if I pass
token_chars=>'=', then 'ab=123' would be parsed to ('ab', '=', '123').
Without token_chars, 'ab=123' remains a single string.

NOTE: you cannot change token_chars after the constructor has been
called!  The regexps that use it are compiled once (m//o).

=item display_summary_in_help

Usually it's easier to have the command's summary (desc) printed first,
then follow it with the documentation (doc).  However, if the doc
already contains its description (for instance, if you're reading it
from a podfile), you don't want the summary up there too.  Pass 0
to prevent printing the desc above the doc.  Defaults to 1.

=back

=cut

sub new
{
    my $type = shift;
    my %args = (
        app => $0,
        prompt => "$0> ",
        commands => undef,
        blank_repeats_cmd => 0,
        backslash_continues_command => 0,
        history_file => undef,
        history_max => 500,
        token_chars => '',
        keep_quotes => 0,
        debug_complete => 0,
        display_summary_in_help => 1,
        @_
    );

    my $self = {};
    bless $self, $type;

    $self->{done} = 0;

    $self->{parser} = Text::Shellwords::Cursor->new(
        token_chars => $args{token_chars},
        keep_quotes => $args{keep_quotes},
        debug => 0,
        error => sub { shift; $self->error(@_); },
        );

    # expand tildes in the history file
    if($args{history_file}) {
        $args{history_file} =~ s/^~([^\/]*)/$1?(getpwnam($1))[7]:
            $ENV{HOME}||$ENV{LOGDIR}||(getpwuid($>))[7]/e;
    }

    for(keys %args) {
        next if $_ eq 'app';    # this param is not a member
        $self->{$_} = $args{$_};
    }

    $self->{term} ||= new Term::ReadLine($args{'app'});
    $self->{term}->MinLine(0);  # manually call AddHistory

    my $attrs = $self->{term}->Attribs;
# there appear to be catastrophic bugs with history_word_delimiters
# it goes into an infinite loop when =,[] are in token_chars
    # $attrs->{history_word_delimiters} = " \t\n".$self->{token_chars};
    $attrs->{completion_function} = sub { completion_function($self, @_); };

    $self->{OUT} = $self->{term}->OUT || \*STDOUT;
    $self->{prevcmd} = "";  # cmd to run again if user hits return

    @{$self->{eof_exit_hooks}} = ();

    return $self;
}


=item process_a_cmd([cmd])

Runs the specified command or prompts for it if no arguments are supplied.
Returns the result or undef if no command was called.

=cut

sub process_a_cmd
{
    my ($self, $incmd) = @_;

    $self->{completeline} = "";
    my $OUT = $self->{'OUT'};

    my $rawline = "";
    if($incmd) {
        $rawline = $incmd;
    } else {
        INPUT_LOOP: for(;;) {
            my $prompt = $self->prompt();
            $prompt = $prompt->[length $rawline ? 1 : 0] if ref $prompt eq 'ARRAY';
            $prompt = $prompt->($self, $rawline) if ref $prompt eq 'CODE';
            my $newline = $self->{term}->readline($prompt);

            # EOF exits
            unless(defined $newline) {
                # If we have eof_exit_hooks let them have a say
                if(scalar(@{$self->{eof_exit_hooks}})) {
                    foreach my $sub (@{$self->{eof_exit_hooks}}) {
                        if(&$sub()) {
                            next INPUT_LOOP;
                        }
                    }
                }

                print $OUT "\n";
                $self->exit_requested(1);
                return undef;
            }

            my $continued = ($newline =~ s/\\$//);
            $rawline .= (length $rawline ? " " : "") . $newline;
            last unless $self->{backslash_continues_command} && $continued;
        }
    }

    # is it a blank line?
    if($rawline =~ /^\s*$/) {
        $rawline = $self->blank_line();
        return unless defined $rawline && $rawline !~ /^\s*$/;
    }

    my $tokens;
    my $expcode = 0;
    my $retval = undef;
    my $str = $rawline;
    my $save_to_history = 1;

    ($tokens) = $self->{parser}->parse_line($rawline, messages=>1);

    if(defined $tokens) {
        $str = $self->{parser}->join_line($tokens);
        if($expcode == 2) {
            # user did an expansion that asked to be printed only
            print $OUT "$str\n";
        } else {
            print $OUT "$str\n" if $expcode == 1;

            my($cset, $cmd, $cname, $args) = $self->get_deep_command($self->commands(), $tokens);

            # this is a subset of the cmpl data structure
            my $parms = {
                cset => $cset,
                cmd => $cmd,
                cname => $cname,
                args => $args,
                tokens => $tokens,
                rawline => $rawline,
            };

            $retval = $self->call_command($parms);

            if(exists $cmd->{exclude_from_history}) {
                $save_to_history = 0;
            }
        }
    }

    # Add to history unless it's a dupe of the previous command.
    if($save_to_history && $str ne $self->{prevcmd}) {
        $self->{term}->addhistory($str);
    }
    $self->{prevcmd} = $str;

    return $retval;
}


=item run()

The main loop.  Processes all commands until someone calls
C<L</"exit_requested(exitflag)"|exit_requested>(true)>.

If you pass arguments, they are joined and run once.  For
instance, $term->run(@ARGV) allows your program to be run
interactively or noninteractively:

=over

=item myshell help

Runs the help command and exits.

=item myshell

Invokes an interactive Term::ShellUI.

=back

=cut

sub run
{
    my $self = shift;
    my $incmd = join " ", @_;

    $self->load_history();
    $self->getset('done', 0);

    while(!$self->{done}) {
        $self->process_a_cmd($incmd);
        last if $incmd;  # only loop if we're prompting for commands
    }

    $self->save_history();
}


# This is a utility function that implements a getter/setter.
# Pass the field to modify for $self, and the new value for that
# field (if any) in $new.

sub getset
{
    my $self = shift;
    my $field = shift;
    my $new = shift;  # optional

    my $old = $self->{$field};
    $self->{$field} = $new if defined $new;
    return $old;
}


=item prompt(newprompt)

If supplied with an argument, this method sets the command-line prompt.
Returns the old prompt.

=cut

sub prompt { return shift->getset('prompt', shift); }


=item commands(newcmds)

If supplied with an argument, it sets the current command set.
This can be used to change the command set at any time.
Returns the old command set.

=cut

sub commands { return shift->getset('commands', shift); }


=item add_commands(newcmds)

Takes a command set as its first argument.
Adds all the commands in it the current command set.
It silently replaces any commands that have the same name.

=cut

sub add_commands
{
    my $self = shift;
    my $cmds = shift;

    my $cset = $self->commands() || {};
    for (keys %$cmds) {
        $cset->{$_} = $cmds->{$_};
    }
}

=item exit_requested(exitflag)

If supplied with an argument, sets Term::ShellUI's finished flag
to the argument (1=exit, 0=don't exit).  So, to get the
interpreter to exit at the end of processing the current
command, call C<$self-E<gt>exit_requested(1)>.  To cancel an exit
request before the command is finished, C<$self-E<gt>exit_requested(0)>.
Returns the old state of the flag.

=cut

sub exit_requested { return shift->getset('done', shift); }

=item add_eof_exit_hook(subroutine_reference)

Call this method to add a subroutine as a hook into Term::ShellUI's
"exit on EOF" (Ctrl-D) functionality. When a user enters Ctrl-D,
Term::ShellUI will call each function in this hook list, in order,
and will exit only if all of them return 0. The first function to
return a non-zero value will stop further processing of these hooks
and prevent the program from exiting.

The return value of this method is the placement of the hook routine
in the hook list (1 is first) or 0 (zero) on failure.

=cut

sub add_eof_exit_hook {
    my $self = shift @_;
    my $refcode = shift @_;
    if(ref($refcode) eq 'CODE') {
        push(@{$self->{eof_exit_hooks}}, $refcode);
        return scalar @{$self->{eof_exit_hooks}};
    }
    return 0;
}

=item get_cname(cname)

This is a tiny utility function that turns the cname (array ref
of names for this command as returned by L</get_deep_command>) into
a human-readable string.
This function exists only to ensure that we do this consistently.

=cut

sub get_cname
{
    my $self = shift;
    my $cname = shift;

    return join(" ", @$cname);
}

=back

=head1 OVERRIDES

These are routines that probably already do the right thing.
If not, however, they are designed to be overridden.

=over

=item blank_line()

This routine is called when the user inputs a blank line.
It returns a string specifying the command to run or
undef if nothing should happen.

By default, ShellUI simply presents another command line.  Pass
C<blank_repeats_cmd=E<gt>1> to L<the constructor|/new> to get ShellUI to repeat the previous
command.  Override this method to supply your own behavior.

=cut

sub blank_line
{
    my $self = shift;

    if($self->{blank_repeats_cmd}) {
        my $OUT = $self->{OUT};
        print $OUT $self->{prevcmd}, "\n";
        return $self->{prevcmd};
    }

    return undef;
}


=item error(msg)

Called when an error occurrs.  By default, the routine simply
prints the msg to stderr.  Override it to change this behavior.
It takes any number of arguments, cocatenates them together and
prints them to stderr.

=cut

sub error
{
    my $self = shift;
    print STDERR @_;
}

=back

=head1 WRITING A COMPLETION ROUTINE

Term::ReadLine makes writing a completion routine a
notoriously difficult task.
Term::ShellUI goes out of its way to make it as easy
as possible.  The best way to write a completion routine
is to start with one that already does something similar to
what you want (see the L</CALLBACKS> section for the completion
routines that come with ShellUI).

Your routine returns an arrayref of possible completions,
a string conaining a short but helpful note,
or undef if an error prevented any completions from being generated.
Return an empty array if there are simply no applicable competions.
Be careful; the distinction between no completions and an error
can be significant.

Your routine takes two arguments: a reference to the ShellUI
object and cmpl, a data structure that contains all the information you need
to calculate the completions.  Set $term->{debug_complete}=5
to see the contents of cmpl:

=over 3

=item str

The exact string that needs completion.  Often, for simple completions,
you don't need anything more than this.

NOTE: str does I<not> respect token_chars!  It is supplied unchanged
from Readline and so uses whatever tokenizing it implements.
Unfortunately, if you've changed token_chars, this will often
be different from how Term::ShellUI would tokenize the same string.

=item cset

Command set for the deepest command found (see L</get_deep_command>).
If no command was found then cset is set to the topmost command
set ($self->commands()).

=item cmd

The command hash for deepest command found or
undef if no command was found (see L</get_deep_command>).
cset is the command set that contains cmd.

=item cname

The full name of deepest command found as an array of tokens
(see L</get_deep_command>).  Use L</get_cname> to convert
this into a human-readable string.

=item args

The arguments (as a list of tokens) that should be passed to the command
(see L</get_deep_command>).  Valid only if cmd is non-null.  Undef if no
args were passed.

=item argno

The index of the argument (in args) containing the cursor.
If the user is trying to complete on the command name, then
argno is negative (because the cursor comes before the arguments).

=item tokens

The tokenized command-line.

=item tokno

The index of the token containing the cursor.

=item tokoff

The character offset of the cursor in the token.

For instance, if the cursor is on the first character of the
third token, tokno will be 2 and tokoff will be 0.

=item twice

True if user has hit tab twice in a row.  This usually means that you
should print a message explaining the possible completions.

If you return your completions as a list, then $twice is handled
for you automatically.  You could use it, for instance, to display
an error message (using L<completemsg|/completemsg(msg)>) telling why no completions
could be found.

=item rawline

The command line as a string, exactly as entered by the user.

=item rawstart

The character position of the cursor in rawline.

=back

The following are utility routines that your completion function
can call.

=over

=item completemsg(msg)

Allows your completion routine to print to the screen while completing
(i.e. to offer suggestions or print debugging info -- see debug_complete).
If it just blindly calls print, the prompt will be corrupted and things
will be confusing until the user redraws the screen (probably by hitting
Control-L).

    $self->completemsg("You cannot complete here!\n");

Note that Term::ReadLine::Perl doesn't support this so the user will always
have to hit Control-L after printing.  If your completion routine returns
a string rather than calling completemsg() then it should work everywhere.

=cut

sub completemsg
{
    my $self = shift;
    my $msg = shift;

    my $OUT = $self->{OUT};
    print $OUT $msg;

    # Now we need to tell the readline library to redraw the entire
    # command line.  Term::ReadLine::Gnu offers rl_on_new_line() but,
    # because it's XS, it can't be detected using can().
    # So, we just eval it and ignore any errors.  If it doesn't exist
    # then the prompt is corrupted.  Oh well, best we can do!
    eval { $self->{term}->rl_on_new_line() };
}


=item suppress_completion_append_character()

When the ReadLine library finds a unique match among the list that
you returned, it automatically appends a space.  Normally this is
what you want (i.e. when completing a command name, in help, etc.)
However, if you're navigating the filesystem, this is definitely
not desirable (picture having to hit backspace after completing
each directory).

Your completion function needs to call this routine every time it
runs if it doesn't want a space automatically appended to the
completions that it returns.

=cut

sub suppress_completion_append_character
{
    shift->{term}->Attribs->{completion_suppress_append} = 1;
}

=item suppress_completion_escape()

Normally everything returned by your completion routine
is escaped so that it doesn't get destroyed by shell metacharacter
interpretation (quotes, backslashes, etc).  To avoid escaping
twice (disastrous), a completion routine that does its own escaping
(perhaps using L<Text::Shellwords::Cursor>parse_escape)
must call suppress_completion_escape every time is called.

=cut

sub suppress_completion_escape
{
    shift->{suppress_completion_escape} = 1;
}


=item force_to_string(cmpl, commmpletions, default_quote)

If all the completions returned by your completion routine should be
enclosed in single or double quotes, call force_to_string on them.
You will most likely need this routine if L<keep_quotes> is 1.
This is useful when completing a construct that you know must
always be quoted.

force_to_string surrounds all completions with the quotes supplied by the user
or, if the user didn't supply any quotes, the quote passed in default_quote.
If the programmer didn't supply a default_quote and the user didn't start
the token with an open quote, then force_to_string won't change anything.

Here's how to use it to force strings on two possible completions,
aaa and bbb.  If the user doesn't supply any quotes, the completions
will be surrounded by double quotes.

     args => sub { shift->force_to_string(@_,['aaa','bbb'],'"') },

Calling force_to_string escapes your completions (unless your callback
calls suppress_completion_escape itself), then calls
suppress_completion_escape to ensure the final quote isn't mangled.

=cut

sub force_to_string
{
    my $self = shift;
    my $cmpl = shift;
    my $results = shift;
    my $bq = shift;      # optional: this is the default quote to use if none

    my $fq = $bq;
    my $try = substr($cmpl->{rawline}, $cmpl->{rawstart}-1, 1);
    if($try eq '"' || $try eq "'") {
        $fq = '';
        $bq = $try;
    }

    if($bq) {
        $self->{parser}->parse_escape($results) unless $self->{suppress_completion_escape};
        for(@$results) {
            $_ = "$fq$_$bq";
        }
        $self->suppress_completion_escape();
    }

    return $results;
}

=back

=head1 INTERNALS

These commands are internal to ShellUI.
They are documented here only for completeness -- you
should never need to call them.

=over

=item get_deep_command

Looks up the supplied command line in a command hash.
Follows all synonyms and subcommands.
Returns undef if the command could not be found.

    my($cset, $cmd, $cname, $args) =
        $self->get_deep_command($self->commands(), $tokens);

This call takes two arguments:

=over 3

=item cset

This is the command set to use.  Pass $self->commands()
unless you know exactly what you're doing.

=item tokens

This is the command line that the command should be read from.
It is a reference to an array that has already been split
on whitespace using L<Text::Shellwords::Cursor::parse_line>.

=back

and it returns a list of 4 values:

=over 3

=item 1.

cset: the deepest command set found.  Always returned.

=item 2.

cmd: the command hash for the command.  Undef if no command was found.

=item 3.

cname: the full name of the command.  This is an array of tokens,
i.e. ('show', 'info').  Returns as deep as it could find commands
even if the final command was not found.

=item 4.

args: the command's arguments (all remaining tokens after the
command is found).

=back

=cut

sub get_deep_command
{
    my $self = shift;
    my $cset = shift;
    my $tokens = shift;
    my $curtok = shift || 0;    # points to the command name

    #print "DBG get_deep_cmd: $#$tokens tokens: '" . join("', '", @$tokens) . "'\n";
    #print "DBG cset: (" . join(", ", keys %$cset) . ")\n";

    my $name = $tokens->[$curtok];

    # loop through all synonyms to find the actual command
    while(exists($cset->{$name}) && (
        exists($cset->{$name}->{'alias'}) ||
        exists($cset->{$name}->{'syn'})
    )) {
        $name = $cset->{$name}->{'alias'} ||
                $cset->{$name}->{'syn'};
    }

    my $cmd = $cset->{$name};

    # update the tokens with the actual name of this command
    $tokens->[$curtok] = $name;

    # should we recurse into subcommands?
    #print "$cmd  " . exists($cmd->{'subcmds'}) . "  (" . join(",", keys %$cmd) . ")   $curtok < $#$tokens\n";
    if($cmd && exists($cmd->{cmds}) && $curtok < $#$tokens) {
        #print "doing subcmd\n";
        my $subname = $tokens->[$curtok+1];
        my $subcmds = $cmd->{cmds};
        return $self->get_deep_command($subcmds, $tokens, $curtok+1);
    }

    #print "DBG splitting (" . join(",",@$tokens) . ") at curtok=$curtok\n";

    # split deep command name and its arguments into separate lists
    my @cname = @$tokens;
    my @args = ($#cname > $curtok ? splice(@cname, $curtok+1) : ());

    #print "DBG tokens (" . join(",",@$tokens) . ")\n";
    #print "DBG cname (" . join(",",@cname) . ")\n";
    #print "DBG args (" . join(",",@args) . ")\n";

    return ($cset, $cmd, \@cname, \@args);
}


=item get_cset_completions(cset)

Returns a list of commands from the passed command set that are suitable
for completing.

=cut

sub get_cset_completions
{
    my $self = shift;
    my $cset = shift;

    # return all commands that aren't exluded from the completion
    # also exclude the default command ''.
    my @c = grep {$_ ne '' && !exists $cset->{$_}->{exclude_from_completion}} keys(%$cset);

    return \@c;
}


=item call_args

Given a command set, does the correct thing at this stage in the
completion (a surprisingly nontrivial task thanks to ShellUI's
flexibility).  Called by complete().

=cut

sub call_args
{
    my $self = shift;
    my $cmpl = shift;

    my $cmd = $cmpl->{cmd};

    my $retval;
    if(exists($cmd->{args})) {
        if(ref($cmd->{args}) eq 'CODE') {
            $retval = eval { &{$cmd->{args}}($self, $cmpl) };
            $self->completemsg($@) if $@;
        } elsif(ref($cmd->{args}) eq 'ARRAY') {
            # each element in array is a string describing corresponding argument
            my $args = $cmd->{args};
            my $argno = $cmpl->{argno};
            # repeat last arg indefinitely (use maxargs to stop)
            $argno = $#$args if $#$args < $argno;
            my $arg = $args->[$argno];
            if(defined $arg) {
                if(ref($arg) eq 'CODE') {
                    # it's a routine to call for this particular arg
                    $retval = eval { &$arg($self, $cmpl) };
                    $self->completemsg($@) if $@;
                } elsif(ref($arg) eq 'ARRAY') {
                    # it's an array of possible completions
                    $retval = @$arg;
                } else {
                    # it's a string reiminder of what this arg is meant to be
                    $self->completemsg("$arg\n") if $cmpl->{twice};
                }
            }
        } elsif(ref($cmd->{args}) eq 'HASH') {
            # not supported yet!  (if ever...)
        } else {
            # this must be a string describing all arguments.
            $self->completemsg($cmd->{args} . "\n") if $cmpl->{twice};
        }
    }

    return $retval;
}

=item complete

This routine figures out the command set of the completion routine
that needs to be called, then calls call_args().  It is called
by completion_function.

You should override this routine if your application has custom
completion needs (like non-trivial tokenizing, where you'll need
to modify the cmpl data structure).  If you override
this routine, you will probably need to override
L<call_cmd|/call_cmd(parms)> as well.

=cut

sub complete
{
    my $self = shift;
    my $cmpl = shift;

    my $cset = $cmpl->{cset};
    my $cmd = $cmpl->{cmd};

    my $cr;
    if($cmpl->{tokno} < @{$cmpl->{cname}}) {
        # if we're still in the command, return possible command completions
        # make sure to still call the default arg handler of course
        $cr = $self->get_cset_completions($cset);
        # fix suggested by Erick Calder
        $cr = [ grep {/^$cmpl->{str}/ && $_} @$cr ];
    }

    if($cr || !defined $cmd) {
        # call default argument handler if it exists
        if(exists $cset->{''}) {
            my %c2 = %$cmpl;
            $c2{cmd} = $cset->{''};
            my $r2 = $self->call_args(\%c2);
            push @$cr, @$r2 if $r2;
        }
        return $cr;
    }

    # don't complete if user has gone past max # of args
    return () if exists($cmd->{maxargs}) && $cmpl->{argno} >= $cmd->{maxargs};

    # everything checks out -- call the command's argument handler
    return $self->call_args($cmpl);
}


=item completion_function

This is the entrypoint to the ReadLine completion callback.
It sets up a bunch of data, then calls L<complete|/complete(cmpl)> to calculate
the actual completion.

To watch and debug the completion process, you can set $self->{debug_complete}
to 2 (print tokenizing), 3 (print tokenizing and results) or 4 (print
everything including the cmpl data structure).

Youu should never need to call or override this function.  If
you do (but, trust me, you don't), set
$self->{term}->Attribs->{completion_function} to point to your own
routine.

See the L<Term::ReadLine> documentation for a description of the arguments.

=cut

sub completion_function
{
    my $self = shift;
    my $text = shift;   # the word directly to the left of the cursor
    my $line = shift;   # the entire line
    my $start = shift;  # the position in the line of the beginning of $text

    my $cursor = $start + length($text);

    # reset the suppress_append flag
    # completion routine must set it every time it's called
    $self->{term}->Attribs->{completion_suppress_append} = 0;
    $self->{suppress_completion_escape} = 0;

    # Twice is true if the user has hit tab twice on the same string
    my $twice = ($self->{completeline} eq $line);
    $self->{completeline} = $line;

    my($tokens, $tokno, $tokoff) = $self->{parser}->parse_line($line,
        messages=>0, cursorpos=>$cursor, fixclosequote=>1);
    return unless defined($tokens);

    # this just prints a whole bunch of completion/parsing debugging info
    if($self->{debug_complete} >= 1) {
        print "\ntext='$text', line='$line', start=$start, cursor=$cursor";

        print "\ntokens=(", join(", ", @$tokens), ") tokno=" .
            (defined($tokno) ? $tokno : 'undef') . " tokoff=" .
            (defined($tokoff) ? $tokoff : 'undef');

        print "\n";
        my $str = " ";
        print     "<";
        my $i = 0;
        for(@$tokens) {
            my $s = (" " x length($_)) . " ";
            substr($s,$tokoff,1) = '^' if $i eq $tokno;
            $str .= $s;
            print $_;
            print ">";
            $str .= "   ", print ", <" if $i != $#$tokens;
            $i += 1;
        }
        $self->completemsg("\n$str\n");
    }

    my $str = $text;

    my($cset, $cmd, $cname, $args) = $self->get_deep_command($self->commands(), $tokens);

    # this structure hopefully contains everything you'll ever
    # need to easily compute a match.
    my $cmpl = {
        str => $str,            # the exact string that needs completion
                                # (usually, you don't need anything more than this)

        cset => $cset,          # cset of the deepest command found
        cmd => $cmd,            # the deepest command or undef
        cname => $cname,        # full name of deepest command
        args => $args,          # anything that was determined to be an argument.
        argno => $tokno - @$cname,  # the argument containing the cursor

        tokens => $tokens,      # tokenized command-line (arrayref).
        tokno => $tokno,        # the index of the token containing the cursor
        tokoff => $tokoff,      # the character offset of the cursor in $tokno.
        twice => $twice,        # true if user has hit tab twice in a row

        rawline => $line,       # pre-tokenized command line
        rawstart => $start,     # position in rawline of the start of str
        rawcursor => $cursor,   # position in rawline of the cursor (end of str)
    };

    if($self->{debug_complete} >= 3) {
        print "tokens=(" . join(",", @$tokens) . ") tokno=$tokno tokoff=$tokoff str=$str twice=$twice\n";
        print "cset=$cset cmd=" . (defined($cmd) ? $cmd : "(undef)") .
            " cname=(" . join(",", @$cname) . ") args=(" . join(",", @$args) . ") argno=".$cmpl->{argno}."\n";
        print "rawline='$line' rawstart=$start rawcursor=$cursor\n";
    }

    my $retval = $self->complete($cmpl);
    $retval = [] unless defined($retval);
    unless(ref($retval) eq 'ARRAY') {
        $self->completemsg("$retval\n") if $cmpl->{twice};
        $retval = [];
    }

    if($self->{debug_complete} >= 2) {
        print "returning (", join(", ", @$retval), ")\n";
    }

    # escape the completions so they're valid on the command line
    $self->{parser}->parse_escape($retval) unless $self->{suppress_completion_escape};

    return @$retval;
}


# Converts a field name into a text string.
# All fields can be code, if so, then they're called to return string value.
# You need to ensure that the field exists before calling this routine.

sub get_field
{
    my $self = shift;
    my $cmd = shift;
    my $field = shift;
    my $args = shift;

    my $val = $cmd->{$field};

    if(ref($val) eq 'CODE') {
        $val = eval { &$val($self, $cmd, @$args) };
        $self->error($@) if $@;
    }

    return $val;
}


=item get_cmd_summary(tokens, cset)

Prints a one-line summary for the given command.
Uses self->commands() if cset is not specified.

=cut

sub get_cmd_summary
{
    my $self = shift;
    my $tokens = shift;
    my $topcset = shift || $self->commands();

    # print "DBG print_cmd_summary: cmd=$cmd args=(" . join(", ", @$args), ")\n";

    my($cset, $cmd, $cname, $args) = $self->get_deep_command($topcset, $tokens);

    my $desc;
    if(!$cmd) {
        if(exists $topcset->{''}) {
            $cmd = $topcset->{''};
        } else {
            return $self->get_cname($cname) . " doesn't exist.\n";
        }
    }

    $desc = $self->get_field($cmd, 'desc', $args) || "(no description)";
    return sprintf("%20s -- $desc\n", $self->get_cname($cname));
}

=item get_cmd_help(tokens, cset)

Prints the full help text for the given command.
Uses self->commands() if cset is not specified.

=cut

sub get_cmd_help
{
    my $self = shift;
    my $tokens = shift;
    my $topcset = shift || $self->commands();

    my $str = "";

    # print "DBG print_cmd_help: cmd=$cmd args=(" . join(", ", @$args), ")\n";

    my($cset, $cmd, $cname, $args) = $self->get_deep_command($topcset, $tokens);
    if(!$cmd) {
        if(exists $topcset->{''}) {
            $cmd = $topcset->{''};
        } else {
            return $self->get_cname($cname) . " doesn't exist.\n";
        }
    }

    if($self->{display_summary_in_help}) {
        if(exists($cmd->{desc})) {
            $str .= $self->get_cname($cname).": ".$self->get_field($cmd,'desc',$args)."\n";
        } else {
            $str .= "No description for " . $self->get_cname($cname) . "\n";
        }
    }

    if(exists($cmd->{doc})) {
        $str .= $self->get_field($cmd, 'doc',
            [$self->get_cname($cname), @$args]);
    } elsif(exists($cmd->{cmds})) {
        $str .= $self->get_all_cmd_summaries($cmd->{cmds});
    } else {
        # no data -- do nothing
    }

    return $str;
}


=item get_category_summary(name, cats)

Prints a one-line summary for the named category
in the category hash specified in cats.

=cut

sub get_category_summary
{
    my $self = shift;
    my $name = shift;
    my $cat = shift;

    my $title = $cat->{desc} || "(no description)";
    return sprintf("%20s -- $title\n", $name);
}

=item get_category_help(cat, cset)

Returns a summary of the commands listed in cat.
You must pass the command set that contains those commands in cset.

=cut

sub get_category_help
{
    my $self = shift;
    my $cat = shift;
    my $cset = shift;

    my $str .= "\n" . $cat->{desc} . "\n\n";
    for my $name (@{$cat->{cmds}}) {
        my @line = split /\s+/, $name;
        $str .= $self->get_cmd_summary(\@line, $cset);
    }
    $str .= "\n";

    return $str;
}


=item get_all_cmd_summaries(cset)

Pass it a command set, and it will return a string containing
the summaries for each command in the set.

=cut

sub get_all_cmd_summaries
{
    my $self = shift;
    my $cset = shift;

    my $str = "";

    for(sort keys(%$cset)) {
        # we now exclude synonyms from the command summaries.
        # hopefully this is the right thing to do...?
        next if exists $cset->{$_}->{alias} || exists $cset->{$_}->{syn};
        # don't show the default command in any summaries
        next if $_ eq '';

        $str .= $self->get_cmd_summary([$_], $cset);
    }

    return $str;
}

=item load_history()

If $self->{history_file} is set (see L</new>), this will load all
history from that file.  Called by L<run|/run()> on startup.  If you
don't use run, you will need to call this command manually.

=cut

sub load_history
{
    my $self = shift;

    return unless $self->{history_file} && $self->{history_max} > 0;

    if(open HIST, '<'.$self->{history_file}) {
        while(<HIST>) {
            chomp();
            next unless /\S/;
            $self->{term}->addhistory($_);
        }
        close HIST;
    }
}

=item save_history()

If $self->{history_file} is set (see L</new>), this will save all
history to that file.  Called by L<run|/run()> on shutdown.  If you
don't use run, you will need to call this command manually.

The history routines don't use ReadHistory and WriteHistory so they
can be used even if other ReadLine libs are being used.  save_history
requires that the ReadLine lib supply a GetHistory call.

=cut

sub save_history
{
    my $self = shift;

    return unless $self->{history_file} && $self->{history_max} > 0;
    return unless $self->{term}->can('GetHistory');

    if(open HIST, '>'.$self->{history_file}) {
        local $, = "\n";
        my @list = $self->{term}->GetHistory();
        if(@list) {
            my $max = $#list;
            $max = $self->{history_max}-1 if $self->{history_max}-1 < $max;
            print HIST @list[$#list-$max..$#list];
            print HIST "\n";
        }
        close HIST;
    } else {
        $self->error("Could not open ".$self->{history_file}." for writing $!\n");
    }
}

=item call_command(parms)

Executes a command and returns the result.  It takes a single
argument: the parms data structure.

parms is a subset of the cmpl data structure (see the L<complete/complete(cmpl)>
routine for more).  Briefly, it contains:
cset, cmd, cname, args (see L</get_deep_command>),
tokens and rawline (the tokenized and untokenized command lines).
See L<complete|/complete(cmpl)> for full descriptions of these fields.

This call should be overridden if you have exotic command
processing needs.  If you override this routine, you will probably
need to override the L<complete|/complete(cmpl)> routine too.

=cut


# This is the low-level version of call_command. It does nothing but call.
# Use call_command -- it's much smarter.

sub call_cmd
{
    my $self = shift;
    my $parms = shift;

    my $cmd = $parms->{cmd};
    my $OUT = $self->{OUT};

    my $retval = undef;
    if(exists $cmd->{meth} || exists $cmd->{method}) {
        my $meth = $cmd->{meth} || $cmd->{method};
        # if meth is a code ref, call it, else it's a string, print it.
        if(ref($meth) eq 'CODE') {
            $retval = eval { &$meth($self, $parms, @{$parms->{args}}) };
            $self->error($@) if $@;
        } else {
            print $OUT $meth;
        }
    } elsif(exists $cmd->{proc}) {
        # if proc is a code ref, call it, else it's a string, print it.
        if(ref($cmd->{proc}) eq 'CODE') {
            $retval = eval { &{$cmd->{proc}}(@{$parms->{args}}) };
            $self->error($@) if $@;
        } else {
            print $OUT $cmd->{proc};
        }
    } else {
        if(exists $cmd->{cmds}) {
            # if not, but it has subcommands, then print a summary
            print $OUT $self->get_all_cmd_summaries($cmd->{cmds});
        } else {
            $self->error("The ". $self->get_cname($parms->{cname}) .
                " command has no proc or method to call!\n");
        }
    }

    return $retval;
}


sub call_command
{
    my $self = shift;
    my $parms = shift;

    if(!$parms->{cmd}) {
        if( exists $parms->{cset}->{''} &&
            (exists($parms->{cset}->{''}->{proc}) ||
             exists($parms->{cset}->{''}->{meth}) ||
             exists($parms->{cset}->{''}->{method})
            )
        ) {
            # default command exists and is callable
            my $save = $parms->{cmd};
            $parms->{cmd} = $parms->{cset}->{''};
            my $retval = $self->call_cmd($parms);
            $parms->{cmd} = $save;
            return $retval;
        }

        $self->error( $self->get_cname($parms->{cname}) . ": unknown command\n");
        return undef;
    }

    my $cmd = $parms->{cmd};

    # check min and max args if they exist
    if(exists($cmd->{minargs}) && @{$parms->{args}} < $cmd->{minargs}) {
        $self->error("Too few args!  " . $cmd->{minargs} . " minimum.\n");
        return undef;
    }
    if(exists($cmd->{maxargs}) && @{$parms->{args}} > $cmd->{maxargs}) {
        $self->error("Too many args!  " . $cmd->{maxargs} . " maximum.\n");
        return undef;
    }

    # everything checks out -- call the command
    return $self->call_cmd($parms);
}

=back

=head1 LICENSE

Copyright (c) 2003-2011 Scott Bronson, all rights reserved.
This program is free software released under the MIT license.

=head1 AUTHORS

Scott Bronson E<lt>bronson@rinspin.comE<gt>
Lester Hightower E<lt>hightowe@cpan.orgE<gt>
Ryan Gies E<lt>ryan@livesite.netE<gt>
Martin Kluge E<lt>mk@elxsi.deE<gt>

=cut

1;
