#!/usr/bin/env perl
use warnings;
use strict;

package MyShell;
use parent qw(Term::Shell::Enhanced);
sub run_date { print scalar localtime, "\n" }
sub smry_date { 'prints the current date and time' }

sub help_date {
    <<EOHELP
This command prints the current date and time as returned
by the localtime() function.
EOHELP
}

package main;
my $shell = MyShell->new;
$shell->print_greeting;
$shell->cmdloop;
