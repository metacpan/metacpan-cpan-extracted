#!/usr/bin/env perl

use 5.014_001;
use warnings;
use Text::ParseWords qw( shellwords );

print "> ";
while (<>) {
    evaluate_input($_);
} continue {
    print "> ";
}
print "\n";
execute_exit('exit', 0);

sub evaluate_input {
    my $cmd_line = shift;
    # Skip comments.
    return if $cmd_line =~ /^\s*(?:#.*)?$/;
    my @cmd_line = shellwords($cmd_line);
    if (!@cmd_line) {
        say STDERR "cannot parse input (unbalanced quote?)";
        return;
    }
    return execute_cp(@cmd_line)    if $cmd_line[0] eq 'cp';
    return execute_echo(@cmd_line)  if $cmd_line[0] eq 'echo';
    return execute_exit(@cmd_line)  if $cmd_line[0] eq 'exit';
    return execute_ls(@cmd_line)    if $cmd_line[0] eq 'ls';
    return execute_make(@cmd_line)  if $cmd_line[0] eq 'make';
    return execute_sleep(@cmd_line) if $cmd_line[0] eq 'sleep';
    say STDERR "unknown command: '$cmd_line[0]'";
}

sub execute_cp {
    my ($cmd, @args) = @_;
    if (@args != 2) {
        say STDERR "$cmd: need exactly two arguments";
        return;
    }
    say "-- $cmd: copying $args[0] to $args[1]";
    say "(would run: cp @args)";
}

sub execute_ls {
    my ($cmd, @args) = @_;
    system('ls', @args);
}

sub execute_echo {
    my ($cmd, @args) = @_;
    say "@args";
}

sub execute_exit {
    my ($cmd, @args) = @_;
    if (@args > 1) {
        say STDERR "$cmd: need at most one argument";
        return;
    }
    my $excode = @args ? $args[0] : 0;
    say "-- exit: $excode";
    exit $excode;
}

sub execute_sleep {
    my ($cmd, @args) = @_;
    if (@args != 1) {
        say STDERR "$cmd: need exactly one argument";
        return;
    }
    say "-- sleep: $args[0]";
    sleep($args[0]);
    say "-- done sleeping";
}

sub execute_make {
    my ($cmd, @args) = @_;
    if (@args != 2) {
        say STDERR "$cmd: need exactly two arguments";
        return;
    }
    if ($args[0] !~ /^(love|money)$/) {
        say STDERR "$cmd: unknown target '$args[0]'";
        return;
    }
    elsif ($args[1] !~ /^(now|later|never|forever)$/) {
        say STDERR "$cmd: unknown period '$args[0]'";
        return;
    }
    say "making $args[0] $args[1]";
}
