# NAME

Parse::CommandLine - Parsing string like command line

# SYNOPSIS

    use Parse::CommandLine;
    my @argv = parse_command_line('command --foo=bar --foo');
    #=> ('command', '--foo-bar', '--foo')

# DESCRIPTION

Parse::CommandLine is a module for parsing string like command line into
array of arguments.

# FUNCTION

## `@command_and_argv = parse_command_line($str)`

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
