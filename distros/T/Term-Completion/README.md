# NAME

Term::Completion - read one line of user input, with convenience functions

# USAGE

```perl
use Term::Completion;
my $tc = Term::Completion->new(
  prompt  => "Enter your first name: ",
  choices => [ qw(Alice Bob Chris Dave Ellen) ]
);
my $name = $tc->complete();
print "You entered: $name\n";
```

# DESCRIPTION

Term::Completion is an extensible, highly configurable replacement for the
venerable [Term::Complete](https://metacpan.org/pod/Term%3A%3AComplete) package. It is object-oriented and thus allows
subclassing. Two derived classes are [Term::Completion::Multi](https://metacpan.org/pod/Term%3A%3ACompletion%3A%3AMulti) and
[Term::Completion::Path](https://metacpan.org/pod/Term%3A%3ACompletion%3A%3APath).

A prompt is printed and the user may enter one line of input, submitting
the answer by pressing the ENTER key. This basic scenario can be implemented
like this:

```perl
my $answer = <STDIN>;
chomp $answer;
```

But often you don't want the user to type in the full word (from a list of
choices), but allow _completion_, i.e. expansion of the word as far as
possible by pressing as few keys as necessary.

Some users like to cycle through the choices, preferably with the
up/down arrow keys.

And finally, you may not want the user to enter any random characters,
but _validate_ what was enter and come back if the entry did not pass
the validation.

If you are missing full line editing (left/right, delete to the left
and right, jump to the beginning and the end etc.), you are probably
wrong here, and want to consider [Term::ReadLine](https://metacpan.org/pod/Term%3A%3AReadLine) and friends.

## Global Setup

The technical challenge for this package is to read single keystrokes from
the input handle - usually STDIN, the user's terminal. There are various ways
how to accomplish that, and Term::Completion supports them all:

- use Term::Completion qw(:stty);

    Use the external `stty` command to configure the terminal. This is what
    [Term::Complete](https://metacpan.org/pod/Term%3A%3AComplete) does, and works fine on systems that have a working
    `stty`. However, using an external command seems like an ugly overhead.
    See also [Term::Completion::\_stty](https://metacpan.org/pod/Term%3A%3ACompletion%3A%3A_stty).

- use Term::Completion qw(:readkey);

    This is the default for all systems, as we assume  you have 
    [Term::ReadKey](https://metacpan.org/pod/Term%3A%3AReadKey) installed. This seems to be the right approach to also
    support various platforms. See also [Term::Completion::\_readkey](https://metacpan.org/pod/Term%3A%3ACompletion%3A%3A_readkey).

- use Term::Completion qw(:POSIX);

    This uses the [POSIX](https://metacpan.org/pod/POSIX) interface (`POSIX::Termios`) to set the
    terminal in the right mode. It should be well portable on UNIX systems.
    See also [Term::Completion::\_POSIX](https://metacpan.org/pod/Term%3A%3ACompletion%3A%3A_POSIX).

## Exports

Term::Completion does not export anything by default, in order not to
pollute your namespace. Here are the exportable methods:

- Complete(...)

    For compatibility with [Term::Complete](https://metacpan.org/pod/Term%3A%3AComplete), you can import the `Complete`
    function:

    ```perl
    use Term::Completion qw(Complete);
    my $result = Complete($prompt, @choices);
    ```

## Methods

Term::Completion objects are simple hashes. All fields are fully
accessible and can be tweaked directly, without accessor methods.

Term::Completion offers the following methods:

- new(...)

    The constructor for Term::Completion objects. Arguments are key/value
    pairs. See ["Configuration"](#configuration) for a description of all
    options. Note that `columns` and `rows` overrides the real terminal
    size from [Term::Size](https://metacpan.org/pod/Term%3A%3ASize).

    Usually you'd supply the list of choices and the prompt string:

    ```perl
    my $tc = Term::Completion->new(
      prompt => "Pick a color: ",
      choices => [ qw(red green blue) ]
    );
    ```

    The object can be reused several times for the same purpose.
    Term::Completion objects are simple hashes. All fields are fully
    accessible and can be tweaked directly, without accessor methods.
    In the example above, you can manipulate the choice list:

    ```
    push(@{$tc->{choices}}, qw(cyan magenta yellow));
    ```

    Note that the constructor won't actually execute the query -
    that is done by the `complete()` method.

- show\_help()

    Print the text stored in the object's `helptext` member variable.

- complete()

    This method executes the query and returns the result string.
    It is guaranteed that the result is a defined value, it may
    however be empty or 0.

- post\_process($answer)

    This method is called on the answer string entered by the user
    after the ENTER key was pressed. The implementation in the base
    class is just stripping any leading and trailing whitespace.
    The method returns the post-processed answer string.

- validate($answer)

    This method is called on the post-processed answer and returns:

    1\. in case of success

    The correct answer string. Please note that the validate method may
    alter the answer, e.g. to adapt it to certain conventions (lowercase
    only).

    2\. in case of failure

    The _undef_ value. This indicates a failure of the validation. In that
    situation an error message should be printed to tell the user why the
    validation failed. This should be done using the following idiom for
    maximum portability:

    ```
    $this->{out}->print("ERROR: no such choice available",
                        $this->{eol});
    ```

    Validation is turned on by the `validate` parameter.
    See ["Predefined Validations"](#predefined-validations) for a list of available
    validation options.

    You can override this method in derived classes to implement
    your own validation strategy - but in some situations this
    could be too much overhead. So the base class accepts an array
    reference for a custom validation callback:

    ```perl
    my $tc = Term::Completion->new(
      prompt => 'Enter voltage: ',
      choices => [ qw(1.2 1.5 1.8 2.0 2.5 3.3) ],
      validate => [
        'Voltage must be a positive, non-zero value' =>
        sub { $_[0] > 0.0 ? $_[0] : undef }
      ]
    );
    ```

    Note that the given code reference will be passed one single argument,
    namely the current input string, and is supposed to return _undef_ if
    the input is invalid, or the (potentially corrected) string, like in the
    example above.

- get\_choices($answer)

    This method returns the items from the choice list which match the
    current answer string. This method is used by the completion algorithm
    and the list of choices. This can be overridden to implement a
    completely different way to get the choices (other than a static list) -
    e.g. by querying a database.

- show\_choices($answer)

    This method is called when the user types CTRL-D (or TAB-TAB) to show the
    list of choices, available with the current answer string. Basically
    `get_choices($answer)` is called and then the list is pretty-printed
    using `_show_choices(...)`.

- \_show\_choices(...)

    Pretty-print the list of items given as arguments. The list is formatted
    into columns, like in UNIX' `ls` command, according to the current
    terminal width (if [Term::Size](https://metacpan.org/pod/Term%3A%3ASize) is available). If the list is long,
    then poor man's paging is enabled, comparable to the UNIX `more`
    command. The user can use ENTER to proceed by one line, SPACE to proceed
    to the next page and Q or CTRL-C to quit paging. After listing the
    choices and return from this method, the prompt and the current answer
    are displayed again.

    Override this method if you have a better pretty-printer/pager. :-)

## Configuration

There is a global hash `%Term::Completion::DEFAULTS` that contains the
default values for all configurable options. Upon object construction
(see ["new(...)"](#new) any of these defaults can be overridden by placing
the corresponding key/value pair in the arguments. Find below the list
of configurable options, their default value and their purpose.

The key definitions are regular expressions (`qr/.../`) - this allows
to match multiple keys for the same action, as well as disable the
action completely by specifying an expression that will never match a 
single character, e.g. `qr/-disable-/`.

- `in`

    The input file handle, default is `\*STDIN`. Can be any filehandle-like
    object, has to understand the `getc()` method.

- `out`

    The output file handle, default is `\*STDOUT`. Can be basically any
    filehandle-like object, has to understand the `print()` method.

- `tab`

    Regular expression matching those keys that should work as the TAB key,
    i.e. complete the current answer string as far as possible, and when
    pressed twice, show the list of matching choices. Default is the tab
    key, i.e. `qr/\t/`.

- `list`

    Regular expression matching those keys that should trigger the listing
    of choices. Default is - like in [Term::Complete](https://metacpan.org/pod/Term%3A%3AComplete) - CTRL-D, i.e.
    `qr/\cd/`.

- `kill`

    Regular expression matching those keys that should delete all input.
    Default is CTRL-U, i.e. `qr/\cu/`.

- `erase`

    Regular expression matching those keys that should delete one character
    (backspace). Default is the BACKSPACE and the DELETE keys, i.e.
    `qr/[\177\010]/`.

- `wipe`

    This is a special control: if either `sep` or `delim` are defined (see
    below), then this key "wipes" all characters (from the right) until (and
    including) the last separator or delimiter. Default is CTRL-W, i.e.
    `qr/\cw/`.

- `enter`

    Regular expression matching those keys that finish the entry process.
    Default is the ENTER key, and for paranoia reasons we use `qr/[\r\n]/`.

- `up`

    Regular expression matching those keys that select the previous item
    from the choice list. Default is CTRL-P, left and up arrow keys, i.e.
    `qr/\cp|\x1b\[[AD]/`.

- `down`

    Regular expression matching those keys that select the next item
    from the choice list. Default is CTRL-N, right and down arrow keys, i.e.
    `qr/\cn|\x1b\[[BC]/`.

- `quit`

    Regular expression matching those keys that exit from paging when the
    list of choices is displayed. Default is 'q' and CTRL-C, i.e.
    `qr/[\ccq]/`.

- `prompt`

    A default prompt string to apply for all Term::Completion objects.
    Default is the empty string.

- `columns`

    Default number of terminal columns for the list of choices. This default
    is only applicable if [Term::Size](https://metacpan.org/pod/Term%3A%3ASize) is unavailable to get the real
    number of columns. The default is 80.

- `rows`

    Default number of terminal rows for the list of choices. This default is
    only applicable if [Term::Size](https://metacpan.org/pod/Term%3A%3ASize) is unavailable to get the real number
    of rows. The default is 24. If set to 0 (zero) there won't be any paging
    when the list of choices is displayed.

- `bell`

    The character which rings the terminal bell, default is `"\a"`. Used
    when completing with the TAB key and there are multiple choices
    available, and when paging is restarted because the terminal size was
    changed.

- `page_str`

    The string to display when max number of lines on the terminal has been
    reached when displaying the choices. Default is `'--more--'`.

- `eol`

    The characters to print for a new line in raw terminal mode. Default is
    `"\r\n"`.

- `del_one`

    The characters to print for deleting one character (to the left).
    Default is `"\b \b"`.

- `help`

    Regular expression matching those keys that print `helptext` on-demand.
    Furthermore, with `help` defined (_undef_), automatic printing of
    `helptext` by the `complete()` method is disabled (enabled).
    Default is _undef_, for backwards compatibility; `qr/\?/` is suggested.

- `helptext`

    This is an optional text which is printed by the `complete()` method
    before the actual completion process starts, unless `help` is defined.
    It may be a multi-line string and should end with a newline character.
    Default is _undef_. The text could for example look like this:

    ```perl
    helptext => <<'EOT',
      You may use the following control keys here:
        TAB      complete the word
        CTRL-D   show list of matching choices (same as TAB-TAB)
        CTRL-U   delete the entire input
        CTRL-H   delete a character (backspace)
        CTRL-P   cycle through choices (backward) (also up arrow)
        CTRL-N   cycle through choices (forward) (also down arrow)
    EOT
    ```

- `choices`

    The default list of choices for all Term::Completion objects (unless
    overridden by the `new(...)` constructor. Has to be an array reference.
    Default is the empty array reference `[]`. Undefined items are
    filtered out.

- `validate`

    Enable validation of the entered string. The value can be either a string
    of comma or blank-separated words, see below for available options; or an
    array reference, containing two scalars: the validation error string and
    a code reference that implements the check.

## Predefined Validations

Whenever you need validation of the user's input, you can always specify
your own code, see ["validate($answer)"](#validate-answer) above. To support everybody's
laziness, there are a couple of predefined validation methods available.
You can specify them as a blank or comma separated string in the
`new(...)` constructor:

```perl
my $tc = Term::Completion->new(
  prompt => 'Fruit: ',
  choices => [ qw(apple banana cherry) ],
  validate => 'nonblank fromchoices'
);
```

In the example above, you are guaranteed the user will choose one of the
given choices. Here's a list of all pre-implemented validations:

- `uppercase`

    Map all the answer string to upper case before proceeding with any
    further validation.

- `lowercase`

    Map all the answer string to lower case before proceeding with any
    further validation.

- `match_one`

    This option has some magic: it tries to match the answer string first at
    the beginning of all choices; if that yields a unique match, the match
    is returned. If not, the answer string is matched at any position in the
    choices, and if that yields a unique match, the match is returned.
    Otherwise an error will be raised that the answer does not match a
    unique item.

- `nonempty`

    Raises an error if the answer has a length of zero characters.

- `nonblank`

    Raises an error if the answer does not contain any non-whitespace
    character.

- `fromchoices`

    Only allow literal entries from the choice list, or the empty
    string. If you don't like the latter, combine this with
    `nonempty`.

- `numeric`

    Only allow numeric values, e.g. -1.234 or 987.

- `integer`

    Only allow integer numbers, e.g. -1 or 234.

- `nonzero`

    Prohibit the numeric value 0 (zero). To avoid warnings about non-numeric
    values, this should be used together with one of `numeric` or `integer`.

- `positive`

    Only allow numeric values greater than zero. To avoid warnings about
    non-numeric values, this should be used together with one of `numeric`
    or `integer`.

This list obviously can be arbitrarily extended. Suggestions (submitted
as patches) are welcome.

# CAVEATS

## Terminal handling

This package temporarily has to set the terminal into 'raw' mode, which
means that all keys lose their special meaning (like CTRL-C, which
normally interrupts the script). This is a highly platform-specific
operation, and therefore this package depends on the portability of
[Term::ReadKey](https://metacpan.org/pod/Term%3A%3AReadKey) and [POSIX](https://metacpan.org/pod/POSIX). Reports about failing platforms are
welcome, but there is probably little that can be fixed here.

## Terminal size changes

This package does the best it can to handle changes of the terminal size
during the completion process. It displays the prompt again and the current
entry during completion, and restarts paging when showing the list of
choices. The latter however only after you press a key - the bell
sounds to indicate that something happened. This is because it does not
seem possible to jump out of a getc().

## Arrow key handling

On UNIX variants, the arrow keys generate a sequence of bytes, starting
with the escape character, followed by a square brackets and others.
Term::Completion accumulates these characters until they either match
this sequence, or not. In the latter case, it will drop the previous
characters and proceed with the last one typed. That however means that
you won't be able to assign the bare escape key to an action. I found
this to be the lesser of the evils. Suggestions on how to solve this in
a clean way are welcome. Yes, I read 
["How can I tell whether there's a character waiting on a filehandle?" in perlfaq5](https://metacpan.org/pod/perlfaq5#How-can-I-tell-whether-theres-a-character-waiting-on-a-filehandle)
but that's probably little portable.

# SEE ALSO

[Term::Complete](https://metacpan.org/pod/Term%3A%3AComplete), [Term::ReadKey](https://metacpan.org/pod/Term%3A%3AReadKey), [Term::Size](https://metacpan.org/pod/Term%3A%3ASize), [POSIX](https://metacpan.org/pod/POSIX),
[Term::ReadLine](https://metacpan.org/pod/Term%3A%3AReadLine)

# AUTHOR

Marek Rouchal, &lt;marekr@cpan.org&lt;gt>

# BUGS

Please submit patches, bug reports and suggestions via the CPAN tracker
[http://rt.cpan.org](http://rt.cpan.org).

# COPYRIGHT AND LICENSE

Copyright (C) 2009-2013 by Marek Rouchal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
