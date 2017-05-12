#!/usr/bin/perl -w
use strict;

use Repl::Core::Parser;
use Repl::Core::Eval;
use Repl::Loop;

use Repl::Cmd::PrintCmd;
use Repl::Cmd::DumpCmd;
use Repl::Cmd::ExitCmd;
use Repl::Cmd::SleepCmd;
use Repl::Cmd::MathCmd;
use Repl::Cmd::LoadCmd;
use Repl::Cmd::FileSysCmd;
use Repl::Cmd::LispCmd;

my $repl = new Repl::Loop;

$repl->registerCommand("print", new Repl::Cmd::PrintCmd);
$repl->registerCommand("exit", new Repl::Cmd::ExitCmd($repl));
$repl->registerCommand("sleep", new Repl::Cmd::SleepCmd());
$repl->registerCommand("dump", new Repl::Cmd::DumpCmd());

Repl::Cmd::MathCmd::registerCommands($repl);
Repl::Cmd::LoadCmd::registerCommands($repl);
Repl::Cmd::FileSysCmd::registerCommands($repl);
Repl::Cmd::LispCmd::registerCommands($repl);

$repl->start();

print "\nDone."

__END__

=head1 NAME

run-loop.pl -- A demo of the Repl::Loop module.

=head1 DESCRIPTION

This script is a demo of the C<Repl::Loop> functionality.
It shows how to instantiate a REPL, add individual commands and
complete command libraries to it and run it.

You probably want to create a similar script, and add
your own command libraries that implement your applications functionality.
