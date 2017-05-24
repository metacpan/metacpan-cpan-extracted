# NAME

Term::ReadLine::Tiny - Tiny implementation of ReadLine

# VERSION

version 1.09

# SYNOPSIS

        use Term::ReadLine::Tiny;
        
        $term = Term::ReadLine::Tiny->new();
        while ( defined($_ = $term->readline("Prompt: ")) )
        {
                print "$_\n";
        }
        print "\n";
        
        $s = "";
        while ( defined($_ = $term->readkey(1)) )
        {
                $s .= $_;
        }
        print "\n$s\n";

# DESCRIPTION

This package is a native perls implementation of ReadLine that doesn&#39;t need any library such as &#39;Gnu ReadLine&#39;.
Also fully supports UTF-8, details in [UTF-8 section](https://metacpan.org/pod/Term::ReadLine::Tiny#UTF-8).

## Keys

**`Enter` or `^J` or `^M`:** Gets input line. Returns the line unless `EOF` or aborting or error, otherwise undef.

**`BackSpace` or `^H` or `^?`:** Deletes one character behind cursor.

**`UpArrow`:** Changes line to previous history line.

**`DownArrow`:** Changes line to next history line.

**`RightArrow`:** Moves cursor forward to one character.

**`LeftArrow`:** Moves cursor back to one character.

**`Home` or `^A`:** Moves cursor to the start of the line.

**`End` or `^E`:** Moves cursor to the end of the line.

**`PageUp`:** Change line to first line of history.

**`PageDown`:** Change line to latest line of history.

**`Insert`:** Switch typing mode between insert and overwrite.

**`Delete`:** Deletes one character at cursor. Does nothing if no character at cursor.

**`Tab` or `^I`:** Completes line automatically by history.

**`^D`:** Aborts the operation. Returns `undef`.

# Standard Methods and Functions

## ReadLine()

returns the actual package that executes the commands. If this package is used, the value is `Term::ReadLine::Tiny`.

## new(\[$appname\[, IN\[, OUT\]\]\])

returns the handle for subsequent calls to following functions.
Argument _appname_ is the name of the application **but not supported yet**.
Optionally can be followed by two arguments for IN and OUT filehandles. These arguments should be globs.

This routine may also get called via `Term::ReadLine->new()` if you have $ENV{PERL\_RL} set to &#39;Tiny&#39;.

## readline(\[$prompt\[, $default\]\])

interactively gets an input line. Trailing newline is removed.

Returns `undef` on `EOF`.

## addhistory($line1\[, $line2\[, ...\]\])

**AddHistory($line1\[, $line2\[, ...\]\])**

adds lines to the history of input.

## IN()

returns the filehandle for input.

## OUT()

returns the filehandle for output.

## MinLine(\[$minline\])

**minline(\[$minline\])**

If argument is specified, it is an advice on minimal size of line to be included into history.
`undef` means do not include anything into history (autohistory off).

Returns the old value.

## findConsole()

returns an array with two strings that give most appropriate names for files for input and output using conventions `"<$in"`, `"`out&quot;&gt;.

## Attribs()

returns a reference to a hash which describes internal configuration of the package. **Not supported in this package.**

## Features()

Returns a reference to a hash with keys being features present in current implementation.
This features are present:

- _appname_ is not present and is the name of the application. **But not supported yet.**
- _addhistory_ is present, always `TRUE`.
- _minline_ is present, default 1. See `MinLine` method.
- _autohistory_ is present. `FALSE` if minline is `undef`. See `MinLine` method.
- _gethistory_ is present, always `TRUE`.
- _sethistory_ is present, always `TRUE`.
- _changehistory_ is present, default `TRUE`. See `changehistory` method.
- _utf8_ is present, default `TRUE`. See `utf8` method.

# Additional Methods and Functions

## newTTY(\[$IN\[, $OUT\]\])

takes two arguments which are input filehandle and output filehandle. Switches to use these filehandles.

## ornaments

This is void implementation. Ornaments is **not supported**.

## gethistory()

**GetHistory()**

Returns copy of the history in Array.

## sethistory($line1\[, $line2\[, ...\]\])

**SetHistory($line1\[, $line2\[, ...\]\])**

rewrites all history by argument values.

## changehistory(\[$changehistory\])

If argument is specified, it allows to change history lines when argument value is true.

Returns the old value.

# Other Methods and Functions

## readkey(\[$echo\])

reads a key from input and echoes if _echo_ argument is `TRUE`.

Returns `undef` on `EOF`.

## utf8(\[$enable\])

If `$enable` is `TRUE`, all read methods return that binary encoded UTF-8 string as possible.

Returns the old value.

## encode\_controlchar($c)

encodes if first character of argument `$c` is a control character,
otherwise returns first character of argument `$c`.

Example: &quot;\\n&quot; is ^J.

## autocomplete($coderef)

Sets a coderef to be used to autocompletion. If `$coderef` is undef,
will restore default behaviour.

The coderef will be called like `$coderef->($term, $line, $ix)`,
where `$line` is the existing line, and `$ix` is the current
location in the history. It should return the completed line, or undef
if completion fails.

# UTF-8

`Term::ReadLine::Tiny` fully supports UTF-8. If no input/output file handle specified when calling `new()` or `newTTY()`,
opens console input/output file handles with `:utf8` layer by `LANG` environment variable. You should set `:utf8`
layer explicitly, if input/output file handles specified with `new()` or `newTTY()`.

        $term = Term::ReadLine::Tiny->new("", $in, $out);
        binmode($term->IN, ":utf8");
        binmode($term->OUT, ":utf8");
        $term->utf8(0); # to get UTF-8 marked string as possible
        while ( defined($_ = $term->readline("Prompt: ")) )
        {
                print "$_\n";
        }
        print "\n";

# KNOWN BUGS

- Cursor doesn&#39;t move to new line at end of terminal line on some native terminals.

# SEE ALSO

- [Term::ReadLine::Tiny::readline](https://metacpan.org/pod/Term::ReadLine::Tiny::readline) - A non-OO package of Term::ReadLine::Tiny
- [Term::ReadLine](https://metacpan.org/pod/Term::ReadLine) - Perl interface to various readline packages

# INSTALLATION

To install this module type the following

        perl Makefile.PL
        make
        make test
        make install

from CPAN

        cpan -i Term::ReadLine::Tiny

# DEPENDENCIES

This module requires these other modules and libraries:

- Term::ReadLine
- Term::ReadKey

# REPOSITORY

**GitHub** [https://github.com/orkunkaraduman/p5-Term-ReadLine-Tiny](https://github.com/orkunkaraduman/p5-Term-ReadLine-Tiny)

**CPAN** [https://metacpan.org/release/Term-ReadLine-Tiny](https://metacpan.org/release/Term-ReadLine-Tiny)

# AUTHOR

Orkun Karaduman (ORKUN) &lt;orkun@cpan.org&gt;

# CONTRIBUTORS

- Adriano Ferreira (FERREIRA) &lt;ferreira@cpan.org&gt;
- Toby Inkster (TOBYINK) &lt;tobyink@cpan.org&gt;

# COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman &lt;orkunkaraduman@gmail.com&gt;

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see &lt;http://www.gnu.org/licenses/&gt;.
