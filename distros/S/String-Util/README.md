# NAME

**String::Util** -- String processing utility functions

# DESCRIPTION

**String::Util** provides a collection of small, handy functions for processing
strings in various ways.

# INSTALLATION

    cpanm String::Util

# USAGE

No functions are exported by default, they must be specified:

    use String::Util qw(trim eqq contains)

alternately you can use `:all` to export **all** of the functions

    use String::Util qw(:all)

# FUNCTIONS

## collapse($string)

`collapse()` collapses all whitespace in the string down to single spaces.
Also removes all leading and trailing whitespace.  Undefined input results in
undefined output.

    $var = collapse("  Hello     world!    "); # "Hello world!"

## hascontent($scalar), nocontent($scalar)

`hascontent()` returns true if the given argument is defined and contains
something besides whitespace.

An undefined value returns false.  An empty string returns false.  A value
containing nothing but whitespace (spaces, tabs, carriage returns, newlines,
backspace) returns false.  A string containing any other characters (including
zero) returns true.

`nocontent()` returns the negation of `hascontent()`.

    $var = hascontent("");  # False
    $var = hascontent(" "); # False
    $var = hascontent("a"); # True

    $var = nocontent("");   # True
    $var = nocontent("a");  # False

## trim($string), ltrim($string), rtrim($string)

Returns the string with all leading and trailing whitespace removed.

    $var = trim(" my string  "); # "my string"

`ltrim()` trims **leading** whitespace only.

`rtrim()` trims **trailing** whitespace only.

## nospace($string)

Removes **all** whitespace characters from the given string. This includes spaces
between words.

    $var = nospace("  Hello World!   "); # "HelloWorld!"

## htmlesc($string)

Formats a string for literal output in HTML.  An undefined value is returned as
an empty string.

htmlesc() is very similar to CGI.pm's escapeHTML.  However, there are a few
differences. htmlesc() changes an undefined value to an empty string, whereas
escapeHTML() returns undefs as undefs.

## jsquote($string)

Escapes and quotes a string for use in JavaScript.  Escapes single quotes and
surrounds the string in single quotes.  Returns the modified string.

## unquote($string)

If the given string starts and ends with quotes, removes them. Recognizes
single quotes and double quotes.  The value must begin and end with same type
of quotes or nothing is done to the value. Undef input results in undef output.
Some examples and what they return:

    unquote(q|'Hendrix'|);   # Hendrix
    unquote(q|"Hendrix"|);   # Hendrix
    unquote(q|Hendrix|);     # Hendrix
    unquote(q|"Hendrix'|);   # "Hendrix'
    unquote(q|O'Sullivan|);  # O'Sullivan

**option:** braces

If the braces option is true, surrounding braces such as \[\] and {} are also
removed. Some examples:

    unquote(q|[Janis]|, braces=>1);  # Janis
    unquote(q|{Janis}|, braces=>1);  # Janis
    unquote(q|(Janis)|, braces=>1);  # Janis

## repeat($string, $count)

Returns the given string repeated the given number of times. The following
command outputs "Fred" three times:

    print repeat('Fred', 3), "\n";

Note that `repeat()` was created a long time based on a misunderstanding of how
the perl operator 'x' works.  The following command using `x` would perform
exactly the same as the above command.

    print 'Fred' x 3, "\n";

Use whichever you prefer.

## eqq($scalar1, $scalar2)

Returns true if the two given values are equal.  Also returns true if both
are `undef`.  If only one is `undef`, or if they are both defined but different,
returns false. Here are some examples and what they return.

    $var = eqq('x', 'x');     # True
    $var = eqq('x', undef);   # False
    $var = eqq(undef, undef); # True

## neqq($scalar1, $scalar2)

The opposite of `neqq`, returns true if the two values are \*not\* the same.
Here are some examples and what they return.

    $var = neqq('x', 'x');     # False
    $var = neqq('x', undef);   # True
    $var = neqq(undef, undef); # False

## ords($string)

Returns the given string represented as the ascii value of each character.

    $var = ords('Hendrix'); # {72}{101}{110}{100}{114}{105}{120}

**options**

- convert\_spaces=>\[true|false\]

    If convert\_spaces is true (which is the default) then spaces are converted to
    their matching ord values. So, for example, this code:

        $var = ords('a b', convert_spaces=>1); # {97}{32}{98}

    This code returns the same thing:

        $var = ords('a b');                    # {97}{32}{98}

    If convert\_spaces is false, then spaces are just returned as spaces. So this
    code:

        ords('a b', convert_spaces=>0);        # {97} {98}

- alpha\_nums

    If the alpha\_nums option is false, then characters 0-9, a-z, and A-Z are not
    converted. For example, this code:

        $var = ords('a=b', alpha_nums=>0); # a{61}b

## deords($string)

Takes the output from `ords()` and returns the string that original created that
output.

    $var = deords('{72}{101}{110}{100}{114}{105}{120}'); # 'Hendrix'

## contains($string, $substring)

Checks if the string contains substring

    $var = contains("Hello world", "Hello");   # true
    $var = contains("Hello world", "llo wor"); # true
    $var = contains("Hello world", "");        # true
    $var = contains("Hello world", "QQQ");     # false
    $var = contains(undef, "QQQ");             # false
    $var = contains("Hello world", undef);     # false

    # Also works with grep
    @arr = grep { contains("cat") } @input;

## startswith($string, $substring)

Checks if the string starts with the characters in substring

    $var = startwith("Hello world", "Hello"); # true
    $var = startwith("Hello world", "H");     # true
    $var = startwith("Hello world", "");      # true
    $var = startwith("Hello world", "Q");     # false
    $var = startwith(undef, "Q");             # false
    $var = startwith("Hello world", undef);   # false

    # Also works with grep
    @arr = grep { startswith("X") } @input;

## endswith($string, $substring)

Checks if the string ends with the characters in substring

    $var = endswith("Hello world", "world");   # true
    $var = endswith("Hello world", "d");       # true
    $var = endswith("Hello world", "");        # true
    $var = endswith("Hello world", "QQQ");     # false
    $var = endswith(undef, "QQQ");             # false
    $var = endswith("Hello world", undef);     # false

    # Also works with grep
    @arr = grep { endswith("z") } @input;

## crunchlines($string)

Compacts contiguous newlines into single newlines.  Whitespace between newlines
is ignored, so that two newlines separated by whitespace is compacted down to a
single newline.

    $var = crunchlines("x\n\n\nx"); # "x\nx";

## sanitize($string, $separator = "\_")

Sanitize all non alpha-numeric characters in a string to underscores.
This is useful to take a URL, or filename, or text description and know
you can use it safely in a URL or a filename.

**Note:** This will remove any trailing or leading '\_' on the string

    $var = sanitize("http://www.google.com/") # http_www_google_com
    $var = sanitize("foo_bar()";              # foo_bar
    $var = sanitize("/path/to/file.txt");     # path_to_file_txt
    $var = sanitize("Big yellow bird!", "."); # Big.yellow.bird

## file\_get\_contents($string, $boolean)

Read an entire file from disk into a string. Returns undef if the file
cannot be read for any reason. Can also return the file as an array of
lines.

    $str   = file_get_contents("/tmp/file.txt");    # Return a string
    @lines = file_get_contents("/tmp/file.txt", 1); # Return an array

**Note:** If you opt to return an array, carriage returns and line feeds are
removed from the end of each line.

**Note:** File is read in **UTF-8** mode, unless `$FGC_MODE` is set to an
appropriate encoding.

## substr\_count($haystack, $needle)

Count the occurences of a substr inside of a larger string. Returns
an integer value with the number of matches, or `undef` if the input
is invalid.

    my $cnt = substr_count("Perl is really rad", "r"); # 3
    my $num = substr_count("Perl is really rad", "Q"); # 0

# COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 by Miko O'Sullivan.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with **NO WARRANTY** of any kind.

# AUTHORS

Miko O'Sullivan <miko@idocs.com>

Scott Baker <scott@perturb.org>
