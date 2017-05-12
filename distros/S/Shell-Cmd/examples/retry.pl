#!/usr/bin/perl

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->cmd(q(../t/bin/fail_twice),{ retry => 3, sleep => 3 });
$obj->run();

