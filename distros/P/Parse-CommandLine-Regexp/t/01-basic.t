#!perl

use strict;
use warnings;
use Test::More 0.98;

use Parse::CommandLine::Regexp qw(parse_command_line);

is_deeply([parse_command_line(q())], []);

is_deeply([parse_command_line(q(one two three))], [qw(one two three)]);

subtest backslash => sub {
    is_deeply([parse_command_line(q(one two\ three))], ['one', 'two three']);
    is_deeply([parse_command_line(q(one two\\\\ three))], ['one', 'two\\', 'three']);
};

subtest "double quote" => sub {
    is_deeply([parse_command_line(q(one "two three"))], ['one', 'two three']);
    is_deeply([parse_command_line(q(one "two three"))], ['one', 'two three']);
    is_deeply([parse_command_line(q(one "two ' three"))], ['one', 'two \' three']);
    is_deeply([parse_command_line(q(one "two \" three"))], ['one', 'two " three']);
    is_deeply([parse_command_line(q(one "two \\ three"))], ['one', 'two  three']);
    is_deeply([parse_command_line(q(one "two \\\\ three"))], ['one', 'two \\ three']);
    is_deeply([parse_command_line(q(one \\"two three))], ['one', '"two', 'three']);
};

subtest "single quote" => sub {
    is_deeply([parse_command_line(q(one 'two three'))], ['one', 'two three']);
    is_deeply([parse_command_line(q(one 'two three))], ['one', 'two three']);
    is_deeply([parse_command_line(q(one 'two " three'))], ['one', 'two " three']);
    is_deeply([parse_command_line(q(one 'two \\ three'))], ['one', 'two  three']);
    is_deeply([parse_command_line(q(one 'two \\\\ three'))], ['one', 'two \\ three']);
    is_deeply([parse_command_line(q(one \\'two three))], ['one', '\'two', 'three']);
};

DONE_TESTING:
done_testing;
