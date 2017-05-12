#!/usr/bin/perl

if (! @ARGV) {
   die "usage: ssh-dry-run.pl HOST HOST ...\n";
}

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->options("mode" => "dry-run");
$obj->cmd(q(echo "Dollar \$ Backtick \` Backslash \\\\ Quote \\""));
$obj->cmd("hostname");
@script = $obj->ssh(@ARGV);

foreach my $script (@script) {
   print $script;
}

