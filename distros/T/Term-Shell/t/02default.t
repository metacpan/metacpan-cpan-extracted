use strict;
use warnings;

use Test::More tests => 6;

package MyShell;
use base qw(Term::Shell);

sub run_command1  { print "command1\n"; }
sub smry_command1 { "what does command1 do?" }
sub help_command1 {
<<'END';
Help on 'command1', whatever that may be...
END
}

sub run_command2 { print "command2\n"; }

package main;

my $shell = MyShell->new;

#=============================================================================
# Command completions
#=============================================================================
my $cmds = [$shell->possible_actions('e', 'run')];
# TEST
is_deeply ($cmds, ['exit'], "e command");

$cmds = [$shell->possible_actions('h', 'run')];
# TEST
is_deeply ($cmds, ['help'], "help command");

$cmds = [$shell->possible_actions('c', 'run')];
# TEST
is(scalar(@$cmds), 2, "c run");

#=============================================================================
# Help completions
#=============================================================================
$cmds = [$shell->possible_actions('e', 'help')];
# TEST
is_deeply ($cmds, ['exit'], "e completions");

$cmds = [$shell->possible_actions('h', 'help')];
# TEST
is_deeply ($cmds, ['help'], 'h completions');

$cmds = [$shell->possible_actions('c', 'help')];
# TEST
is_deeply ($cmds, ['command1'], 'command1 completions');
