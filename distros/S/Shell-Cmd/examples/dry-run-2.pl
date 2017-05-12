#!/usr/bin/perl

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->options("mode" => "dry-run");
$obj->cmd("if [ -d /tmp/1 ]; then",
          "echo 'case 1'",
          "elif [ -d /tmp/2 ]; then",
          "echo 'case 2'",
          "if [ -d /tmp/2/a ]; then",
          "echo 'case 2a'", 
          "fi",
          "fi",
         );
($script) = $obj->run();

print $script;

