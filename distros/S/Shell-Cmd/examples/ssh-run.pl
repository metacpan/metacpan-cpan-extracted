#!/usr/bin/perl

if (! @ARGV) {
   die "usage: ssh-run.pl HOST HOST ...\n";
}

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->options("mode" => "run");
$obj->cmd(q(echo "Dollar \$ Backtick \` Backslash \\\\ Quote \\""));
$obj->cmd("hostname");
$obj->ssh(@ARGV);
