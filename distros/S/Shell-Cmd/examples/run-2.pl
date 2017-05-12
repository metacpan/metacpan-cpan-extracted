#!/usr/bin/perl

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->options("mode" => "run");
$obj->cmd("if [ -d /tmp ]; then",
          "ls /tmp",
          "fi",
         );
($err) = $obj->run();

print "ERROR: $err\n";

