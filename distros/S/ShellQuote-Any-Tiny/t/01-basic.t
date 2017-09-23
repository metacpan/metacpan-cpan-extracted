#!perl

use strict;
use warnings;
use Test::More 0.98;

use ShellQuote::Any::Tiny qw(shell_quote);

test_echo(arg => '', result => '');
test_echo(arg => ' ', result => ' ');
test_echo(arg => 'hello', result => 'hello');
test_echo(arg => 'hello world', result => 'hello world');

test_echo(arg => 'a\\', result => 'a\\');
test_echo(arg => 'a\\\\', result => 'a\\\\');
test_echo(arg => 'a\\ \\', result => 'a\\ \\');
test_echo(arg => 'a\\ \\\\', result => 'a\\ \\\\');

test_echo(arg => "'", result => "'");

test_echo(arg => '"', result => '"');
test_echo(arg => '"abc" d e', result => '"abc" d e');
test_echo(arg => 'a\\\\\\b d"e f"g h', result => 'a\\\\\\b d"e f"g h');
test_echo(arg => 'a\\\\\\"b c d', result => 'a\\\\\\"b c d');
test_echo(arg => 'a\\\\\\\\"b c" d e', result => 'a\\\\\\\\"b c" d e');

done_testing;

sub test_echo {
    my %args = @_;

    subtest +($args{name} || $args{arg}) => sub {
        my $cmd;
        if ($^O eq 'MSWin32') {
            $cmd = "\"$^X\" -e\"print \$ARGV[0]\" ".shell_quote($args{arg});
        } else {
            $cmd = "'$^X' -e'print \$ARGV[0]' ".shell_quote($args{arg});
        }
        #diag "CMD: $cmd";
        my $result = `$cmd`;
        chomp($result);
        is($result, $args{result}, "result");
    };
}
