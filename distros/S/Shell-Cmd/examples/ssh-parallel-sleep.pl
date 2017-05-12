#!/usr/bin/perl

if (! @ARGV) {
   die "usage: ssh-parallel-sleep.pl HOST HOST ...\n";
}

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->options("mode"  => "run");
$obj->options("ssh_num" => 5);
$obj->options("ssh_sleep" => 10);
$obj->cmd("hostname");
$obj->ssh(@ARGV);
