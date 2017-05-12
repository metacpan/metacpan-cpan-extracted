#!/usr/bin/perl
# $Id: wheel-run.perl 146 2007-01-07 06:51:22Z rcaputo $

# Attempt to use POE::Watcher::Wheel to encapsulate POE::Wheel::Run.

{
	package App;
	use lib qw(./lib ../lib);
	use POE::Stage::App qw(:base);
	use POE::Watcher::Wheel::Run;
	use POE::Filter::Line;

	sub on_run :Handler {
		my $req_process = POE::Watcher::Wheel::Run->new(
			Program      => "$^X -wle 'print qq[pid(\$\$) moo(\$_)] for 1..10; exit'",
			StdoutMethod => "handle_stdout",
			CloseMethod  => "handle_close",
		);
	}

	sub handle_stdout :Handler {
		my $args = $_[1];
		use YAML;
		warn YAML::Dump($args);
	}

	sub handle_close :Handler {
		warn "process closed";
		my $req_process = undef;
	}
}

package main;

# Avoid POE messages:
# !!! Child process PID:20840 reaped:
$SIG{CHLD} = "IGNORE";

App->new()->run();
exit;
