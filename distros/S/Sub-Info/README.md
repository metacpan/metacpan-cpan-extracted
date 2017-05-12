# NAME

Sub::Info - Tool for inspecting subroutines.

# DESCRIPTION

Tool to inspect subroutines.

# EXPORTS

All exports are optional, you must specify subs to import.

- my $hr = sub\_info(\\&code)
- my $hr = sub\_info(\\&code, @line\_numbers)

    This returns a hashref with information about the sub:

        {
            ref        => \&code,
            cobj       => $cobj,
            name       => "Some::Mod::code",
            file       => "Some/Mod.pm",
            package    => "Some::Mod",

            # Note: These have been adjusted based on guesswork.
            start_line => 22,
            end_line   => 42,
            lines      => [22, 42],

            # Not a bug, these lines are different!
            all_lines  => [23, 25, ..., 39, 41],
        };

    - $info->{ref} => \\&code

        This is the original sub passed to `sub_info()`.

    - $info->{cobj} => $cobj

        This is the c-object representation of the coderef.

    - $info->{name} => "Some::Mod::code"

        This is the name of the coderef. For anonymous coderefs this may end with
        `'__ANON__'`. Also note that the package 'main' is special, and 'main::' may
        be omitted.

    - $info->{file} => "Some/Mod.pm"

        The file in which the sub was defined.

    - $info->{package} => "Some::Mod"

        The package in which the sub was defined.

    - $info->{start\_line} => 22
    - $info->{end\_line} => 42
    - $info->{lines} => \[22, 42\]

        These three fields are the _adjusted_ start line, end line, and array with both.
        It is important to note that these lines have been adjusted and may not be
        accurate.

        The lines are obtained by walking the ops. As such, the first line is the line
        of the first statement, and the last line is the line of the last statement.
        This means that in multi-line subs the lines are usually off by 1.  The lines
        in these keys will be adjusted for you if it detects a multi-line sub.

    - $info->{all\_lines} => \[23, 25, ..., 39, 41\]

        This is an array with the lines of every statement in the sub. Unlike the other
        line fields, these have not been adjusted for you.

# SOURCE

The source code repository for Sub-Info can be found at
`http://github.com/exodist/Sub-Info/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>
- Kent Fredric <kentnl@cpan.org>

# COPYRIGHT

Copyright 2016 Chad Granum <exodist@cpan.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
