package RL;
use strict;
use warnings;
use XSLoader;

our $VERSION = "0.08";
XSLoader::load();

sub completion_helper {
    my ($text, $array) = @_;
    my @matching;
    for my $item (@$array) {
        if ($item =~ /^\Q$text\E/i) {
            push @matching, $item;
        }
    }
    return @matching if @matching < 2;
    my @matching2 = sort @matching;
    my $item1 = $matching2[0];
    my $itemn = $matching2[-1];
    my $i;
    for ($i = 0; $i < length($item1); $i++) {
        if (substr($item1, $i, 1) ne substr($itemn, $i, 1)) {
            last;
        }
    }
    unshift @matching, substr($item1, 0, $i);
    return @matching;
}

sub history_list {
    my $i = history_base();
    my @list;
    while (1) {
        my $item = history_get($i);
        if (!defined $item) {
            last;
        }
        push @list, $item;
        $i++;
    }
    return @list;
}

1;

__END__

=encoding utf8

=head1 NAME

RL - Perl interface to the readline library

=head1 SYNOPSIS

    use RL;
    while (1) {
        my $line = RL::readline("prompt: ");
        if (!defined $line) {
            print "\n";
            last;
        }
        if ($line =~ /^(q|quit|e|exit)$/) {
            last;
        }
        if (length($line)) {
            print "$line\n";
            RL::add_history($line);
        }
    }

=head1 DESCRIPTION

This module provides an interface to the readline library. On Linux,
it would be the readline library provided by GNU. On OS X, it is
the emulated readline library that is actually the libedit library.
This library only provides the subset of functionality that both
provide, so some things are missing intentionally.  This also
includes an interface to the history library functions.

If you're using a Mac, you may notice bash reads .inputrc since
bash is statically linked with GNU readline, but this library isnt
available for linking into other programs. I've also noticed libedit
doesn't handle ansi escape codes in the prompt well, even though
it mentions \1 and \2 in its header file (the codes are used around
ansi escape codes in readline to specify they are 0 width).

No subroutines are exported, you must access all within the RL
namespace. for example, instead of C<readline($prompt)>, you
would write C<RL::readline($prompt)>.

This package also comes with a script called pl, which is a repl
for the Perl language, to quickly test commands, or do mathematical
calculations, etc.

Recommendation: Add the following to your .editrc file to get
previous and next history entries that match your partially typed
command (only for OS X's readline):

    bind ^[[A ed-search-prev-history
    bind ^[[B ed-search-next-history

For Linux, you would put this into your .inputrc:

    "\e[A": history-search-backward
    "\e[B": history-search-forward

=head1 MAIN INTERFACE

=head2 readline($prompt)

Prompts the user for input and returns the string they gave you.

=head1 READLINE VARIABLES

These variables in the readline library are exported to Perl space
as getter/setter functions. Readonly variables do not take arguments.

=head2 line_buffer([$string])

Returns the value of the current line buffer. Optionally sets it
to $string, if provided.

=head2 point([$int])

Returns the position of the cursor in the input line. Optionally
sets it to $int.

=head2 end([$int])

Returns the position at the end of the input line. Optionally sets
it to $int.

=head2 prompt

Returns the string that is shown before the place where the user
types.

=head2 already_prompted([$int])

Returns whether the user was already prompted. Optionally, you can
set it to $int.

=head2 library_version

Returns what the library version is. e.g. "EditLine wrapper".

=head2 readline_version

Returns what version of readline it is in integer form. e.g. 1026.

=head2 terminal_name([$string])

Gets or sets the terminal name which is used to figure out which
terminfo entry to use.

=head2 readline_name([$string])

Gets or sets the readline name which is used to supply conditional
parameters in the .inputrc (or .editrc) config file that influence
your program individually.

=head2 instream([$fh])

Gets or sets the instream, rl_instream, for readline to use some way.

=head2 outstream([$fh])

Gets or sets the outstream, rl_outstream, for readline to use some way.

=head2 startup_hook($func)

Sets the startup hook, rl_startup_hook, that gets called when
readline initializes itself. Set it to undef to remove the hook.
For example:

    RL::startup_hook(sub {print "Hello, world\n"});

=head2 pre_input_hook($func)

Sets the pre input hook, rl_pre_input_hook, that gets called after
the prompt but before readline reads input from the user. Set to
undef to remove the hook. For example:

    RL::pre_input_hook(sub {print "Hello, world\n"});

=head2 getc_function($func)

Sets the getc function that readline uses to read a character from
the user. Set it to undef to get back default behavior. For example:

    RL::getc_function(sub {
        sleep 1;
        return ord("x");
    });

=head1 BINDING KEYS

=head2 bind_key($key, $func)

Bind a function to the key.

=head2 parse_and_bind($line)

Parses a line as if it were in the .inputrc or .editrc file. For example:

    RL::initialize();
    RL::parse_and_bind("bind -v\n");

Would set vi mode on OS X's readline. Note: you need to call
initialize first or else you get a segfault.

=head2 read_init_file($filename)

Read keybindings and variable assignments from filename.

=head1 REDISPLAY

=head2 redisplay

Redisplays the contents of readline's line buffer.

=head2 forced_update_display

Force the line to be updated and redisplayed, whether or not Readline
thinks the screen display is correct.

=head2 on_new_line

Tell the update functions that we have moved onto a new (empty)
line, usually after outputting a newline.

=head2 set_prompt($prompt)

Make Readline use prompt for subsequent redisplay.

=head1 MODIFYING TEXT

=head2 insert_text(text)

Insert text into the line at the current cursor position. Returns
the number of characters inserted.

=head1 CHARACTER INPUT

=head2 read_key

Return the next character available from Readline's current input
stream.

=head2 stuff_char($char)

Insert c into the Readline input stream.

=head1 UTILITY FUNCTIONS

=head2 initialize

Initialize or re-initialize Readline's internal state. It's not
strictly necessary to call this; readline() calls it before reading
any input.

=head1 COMPLETION FUNCTIONS

=head2 complete($count, $key)

Complete the word at or before point.

=head2 completion_matches($text, $func)

Returns a list of strings which could complete text using the
completion entry function $func.

=head2 filename_completion_function($text, $state)

A function that completes filenames. Use it to provide completion_matches()
or completion_entry_function() a function that completes filenames.
For example:

    my @array = RL::completion_matches(
        "Re", \&RL::filename_completion_function);
    print "$_\n" for @array;

or:

    RL::completion_entry_function(
        \&RL::filename_completion_function);

=head2 username_completion_function($text, $func)

A subroutine that completes usernames to be used with other subroutines
that expects a subroutine like this one.

=head1 COMPLETION VARIABLES

=head2 completion_entry_function($func)

Sets the subroutine for completion entries. If set to undef, it
will revert to filename completion. The subroutine is supplied with
the text of the word under the cursor and a state counter, which
will start at 0 and increment until you return undef. For example:

    my @list = ("Apple", "Pear", "Banana", "Orange");
    my $index = 0;

    RL::completion_entry_function(sub {
        my ($text, $state) = @_;
        if ($state == 0) {
            $index = 0;
        }
        my $item;
        for (; $index < @list; $index++) {
            $item = $list[$index];
            if ($item =~ /$text/i) {
                $index++;
                return $item;
            }
        }
        return undef;
    });
    RL::readline("prompt: ");

=head2 attempted_completion_function($func)

Calling this lets you specify a different format of completion
function to the completion_entry_function(). This callback is
executed when the user presses tab, and receives $text, a $start
position, and an $end position, and you return a list of completions
as as an array.  The first element is the part to complete right
away.

So if you typed "a" and the completions were "abc1", "abc2", and
"abc3", the list returned would be "abc", "abc1", "abc2", and "abc3".
Hitting tab would complete up to "abc" and then let you see the
other possible completions. A helper function called completion_helper()
is provided to help go from a list of possible completions to the
format required by this function. For example:

    RL::attempted_completion_function(sub {
        my ($text, $start, $end) = @_;
        my @array = ("Cat", "Dog", "Fish", "Bread", "Fax", "Fox",
                     "Chipmunk", "Chimpanzee", "Cheetah", "Mouse",
                     "Three Toed Sloth");
        return RL::completion_helper($text, \@array);
    });
    RL::readline("prompt: ");

=head2 completion_helper($text, $array)

This subroutine takes text and a list of possible completions and
returns a list of completions which could possibly match the text.
It returns the result in the format required by
attempted_completion_function().

=head2 basic_word_break_characters([$string])

This is the list of characters that readline will consider a word
break. readline can only replace what it considers to be one word.
The default is " \t\n\"\\'`@$><=;|&{("

=head2 completer_word_break_characters([$string])

Like basic_word_break_characters() but for another part of readline.

=head2 completion_word_break_hook($func)

Set this to a subroutine that returns the word break character
string and readline will use it somehow.

=head2 completer_quote_characters([$string])

A list of characters which can be used to quote a substring of the line.

=head2 special_prefixes([$string])

The list of characters that are word break characters, but should
be left in text when it is passed to the completion function.
Programs can use this to help determine what kind of completing to
do. For instance, Bash sets this variable to "$@" so that it can
complete shell variables and hostnames.

=head2 completion_query_items([$int])

Up to this many items will be displayed in response to a
possible-completions call. After that, readline asks the user if
she is sure she wants to see them all. The default value is 100. A
negative value indicates that Readline should never ask the user.

=head2 completion_append_character([$int])

When a single completion alternative matches at the end of the
command line, this character is appended to the inserted completion
text. The default is a space character (` '). Setting this to the
null character (`\0') prevents anything being appended automatically.
This can be changed in application-specific completion functions
to provide the "most sensible word separator character" according
to an application-specific command line syntax specification.

=head2 ignore_completion_duplicates([$int])

If non-zero, then duplicates in the matches are removed. The default is 1.

=head2 filename_completion_desired([$int])

When done with completion add a slash to directories.

=head2 attempted_completion_over([$int])

Specify that completion is over, don't try and complete filenames.

=head2 completion_type([$int])

An integer (actually a character) specifying the completion type.

=head2 inhibit_completion([$int])

Disable completion.

=head1 HISTORY INITIALIZATION

=head2 using_history

Initializes internal variables for the history library.

=head1 HISTORY LIST MANAGEMENT

=head2 add_history($string)

Adds the string into readline history. You can recall the string
using up and down arrow keys.

=head2 clear_history

Clears the history list.

=head1 INFORMATION ABOUT THE HISTORY LIST

=head2 history_list

Returns a list of all the items in history.

=head2 where_history

Where in the history list we currently are.

=head2 current_history

The current entry in history.

=head2 history_get($int)

Get's the history entry at position $int.

=head2 history_total_bytes

The sum of the bytes of all the strings in history.

=head1 MOVING AROUND THE HISTORY LIST

=head2 history_set_pos($int)

Sets the history position to the given parameter.

=head1 MANAGING THE HISTORY FILE

=head2 read_history($filename)

Add the contents of filename to the history list, a line at a time.
Returns 0 if successful, or errno if not.

=head2 write_history($filename)

Writes history to filename. Returns 0 if successful, errno if not.

=head2 history_truncate_file($filename, $nlines)

Truncates the history file, to just nlines number of lines.

=head1 HISTORY EXPANSION

=head2 history_expand($string)

Returns the string with history expanded. For example, !! becomes
the previously input string.

=head1 HISTORY VARIABLES

=head2 history_base

The logical offset of the first entry in the history list.

=head2 history_length

The number of entries currently stored in the history list.

=head1 SEE ALSO

The readline docs:

=over

=item https://cnswww.cns.cwru.edu/php/chet/readline/readline.html

=item https://cnswww.cns.cwru.edu/php/chet/readline/history.html

=item https://cnswww.cns.cwru.edu/php/chet/readline/rluserman.html

=back

Editline init file format:

=over

=item https://www.mankier.com/5/editrc

=back

=head1 METACPAN

L<https://metacpan.org/pod/RL>

=head1 REPOSITORY

L<https://github.com/zorgnax/perlreadline>

=head1 AUTHOR

Jacob Gelbman, E<lt>gelbman@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Jacob Gelbman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

