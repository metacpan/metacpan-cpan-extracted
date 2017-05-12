#!/usr/bin/perl

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->cmd(q(echo "Dollar \$ Backtick \` Backslash \\\\ Quote \\""));
$obj->cmd("ls /tmp");
$obj->run();

