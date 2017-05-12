# NAME

Template::Twostep - Compile templates into a subroutine

# SYNOPSIS

    use Template::Twostep;
    my $tt = Template::Twostep->new;
    my $sub = $tt->compile($template, $subtemplate);
    my $output = $sub->($hash);

# DESCRIPTION

This module simplifies the job of producing html text output by letting
you put data into a template. Templates support the control structures in
Perl: "for" and "while" loops, "if-else" blocks, and some others. Creating output
is a two step process. First you generate a subroutine from one or more
templates, then you call the subroutine with your data to generate the output.

The template format is line oriented. Commands occupy a single line and continue
to the end of line. By default commands are enclosed in html comments (<!--
\-->), but the command start and end strings are configurable via the new method.
A command may be preceded by white space. If a command is a block command, it is
terminated by the word "end" followed by the command name. For example, the
"for" command is terminated by an "endfor" command and the "if" command by an
"endif" command.

All lines may contain variables. As in Perl, variables are a sigil character
('$,' '@,' or '%') followed by one or more word characters. For example,
`$name` or `@names`. To indicate a literal character instead of a variable,
precede the sigil with a backslash. When you run the subroutine that this module
generates, you pass it a reference, usually a reference to a hash, containing
some data. The subroutine replaces variables in the template with the value in
the field of the same name in the hash. If the types of the two disagree, the
code will coerce the data to the type of the sigil. You can pass a reference to
an array instead of a hash to the subroutine this module generates. If you do,
the template will use `@data` to refer to the array.

There are several other template packages. I wrote this one to have the specific
set of features I want in a template package. First, I wanted templates to be
compiled into code. This approach has the advantage of speeding things up when
the same template is used more than once. However, it also poses a security risk
because code you might not want executed may be included in the template. For
this reason if the script using this module can be run from the web, make sure
the account that runs it cannot write to the template. I made the templates
command language line oriented rather than tag oriented to prevent spurious
white space from appearing in the output. Template commands and variables are
similar to Perl for familiarity. The power of the template language is limited
to the essentials for the sake of simplicity and to prevent mixing code with
presentation.

# METHODS

This module has two public methods. The first, new, changes the module
defaults. Compile generates a subroutine from one or more templates. You Tthen
call this subroutine with a reference to the data you want to substitute into
the template to produce output.

Using subtemplates along with a template allows you to place the common design
elements in the template. You indicate where to replace parts of the template
with parts of the subtemplate by using the "section" command. If the template
contains a section block with the same name as a section block in the
subtemplates it replaces the contents inside the section block in the template
with the contents of the corresponding block in the subtemplate.

- `$obj = Template::Twostep->new(command_start => '::', command_end => '');`

    Create a new parser. The configuration allows you to set a set of characters to
    escape when found in the data (escaped\_chars), the string which starts a command
    (command\_start), the string which ends a command (command\_end), and whether
    section comments are kept in the output (keep\_sections). All commands end at the
    end of line. However, you may wish to place commands inside comments and
    comments may require a closing string. By setting command\_end, the closing
    string will be stripped from the end of the command.

- `$sub = $obj->compile($template, $subtemplate);`

    Generate a subroutine used to render data from a template and optionally from
    one or more subtemplates. It can be invoked by an object created by a call to
    new, or you can invoke it using the package name (Template::Twostep), in which
    case it will first call new for you. If the template string does not contain a
    newline, the method assumes it is a filename and it reads the template from that
    file.

# TEMPLATE SYNTAX

If the first non-white characters on a line are the command start string, the
line is interpreted as a command. The command name continues up to the first
white space character. The text following the initial span of white space is the
command argument. The argument continues up to the command end string, or if
this is empty, to the end of the line.

Variables in the template have the same format as ordinary Perl variables,
a string of word characters starting with a sigil character. for example,

    $SUMMARY @data %dictionary

are examples of variables. The subroutine this module generates will substitute
values in the data it is passed for the variables in the template. New variables
can be added with the "set" command.

Arrays and hashes are rendered as unordered lists and definition lists when
interpolating them. This is done recursively, so arbitrary structures can be
rendered. This is mostly intended for debugging, as it does not provide fine
control over how the structures are rendered. For finer control, use the
commands described below so that the scalar fields in the structures can be
accessed. Scalar fields have the characters '<' and '>' escaped before
interpolating them. This set of characters can be changed by setting the
configuration parameter escaped chars. Undefined fields are replaced with the
empty string when rendering. If the type of data passed to the subroutine
differs from the sigil on the variable the variable is coerced to the type of
the sigil. This works the same as an assignment. If an array is referenced as a
scalar, the length of the array is output.

The following commands are supported in templates:

- do

    The remainder of the line is interpreted as Perl code. For assignments, use
    the set command.

- each

    Repeat the text between the "each" and "endeach" commands for each entry in the
    hash table. The hast table key can be accessed through the variable $key and
    the hash table value through the variable $value. Key-value pairs are returned
    in random order. For example, this code displays the contents of a hash as a
    list:

        <ul>
        <!-- each %hash -->
        <li><b>$key</b> $value</li>
        <!-- endeach -->
        </ul>

- for

    Expand the text between the "for" and "endfor" commands several times. The
    "for" command takes a name of a field in a hash as its argument. The value of this
    name should be a reference to a list. It will expand the text in the for block
    once for each element in the list. Within the "for" block, any element of the list
    is accessible. This is especially useful for displaying lists of hashes. For
    example, suppose the data field name PHONELIST points to an array. This array is
    a list of hashes, and each hash has two entries, NAME and PHONE. Then the code

        <!-- for @PHONELIST -->
        <p>$NAME<br>
        $PHONE</p>
        <!-- endfor -->

    displays the entire phone list.

- if

    The text until the matching `endif` is included only if the expression in the
    "if" command is true. If false, the text is skipped. The "if" command can contain
    an `else`, in which case the text before the "else" is included if the
    expression in the "if" command is true and the text after the "else" is included
    if it is false. You can also place an "elsif" command in the "if" block, which
    includes the following text if its expression is true.

        <!-- if $highlight eq 'y' -->
        <em>$text</em>
        <!-- else -->
        $text
        <!-- endif -->

- section

    If a template contains a section, the text until the endsection command will be
    replaced by the section block with the same name in one the subtemplates. For
    example, if the main template has the code

        <!-- section footer -->
        <div></div>
        <!-- endsection -->

    and the subtemplate has the lines

        <!-- section footer -->
        <div>This template is copyright with a Creative Commons License.</div>
        <!-- endsection -->

    The text will be copied from a section in the subtemplate into a section of the
    same name in the template. If there is no block with the same name in the
    subtemplate, the text is used unchanged.

- set

    Adds a new variable or updates the value of an existing variable. The argument
    following the command name looks like any Perl assignment statement minus the
    trailing semicolon. For example,

        <!-- set $link = "<a href=\"$url\">$title</a>" -->

- while

    Expand the text between the `while` and `endwhile` as long as the
    expression following the `while` is true.

        <!-- set $i = 10 -->
        <p>Countdown ...<br>
        <!-- while $i >= 0 -->
        $i<br>
        <!-- set $i = $i - 1 -->
        <!-- endwhile -->

- with

    Lists within a hash can be accessed using the "for" command. Hashes within a
    hash are accessed using the "with" command. For example:

        <!-- with %address -->
        <p><i>$street<br />
        $city, $state $zip</i></p.
        <!-- endwith -->

# ERRORS

What to check when this module throws an error

- Couldn't read template

    The template is in a file and the file could not be opened. Check the filename
    and permissions on the file. Relative filenames can cause problems and the web
    server is probably running another account than yours.

- Illegal type conversion

    The sigil on a variable differs from the data passed to the subroutine and
    conversion. between the two would not be legal. Or you forgot to escape the '@'
    in an email address by preceding it with a backslash.

- Unknown command

    Either a command was spelled incorrectly or a line that is not a command
    begins with the command start string.

- Missing end

    The template contains a command for the start of a block, but
    not the command for the end of the block. For example  an "if" command
    is missing an "endif" command.

- Mismatched block end

    The parser found a different end command than the begin command for the block
    it was parsing. Either an end command is missing, or block commands are nested
    incorrectly.

- Syntax error

    The expression used in a command is not valid Perl.

# LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Bernie Simon <bernie.simon@gmail.com>
