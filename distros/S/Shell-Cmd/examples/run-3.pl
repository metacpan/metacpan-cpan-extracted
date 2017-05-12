#!/usr/bin/perl

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->options("mode" => "run");
$obj->options("failure" => "display");
$obj->options('tmp_script','/tmp/z.sh','tmp_script_keep',1);

$obj->cmd("if [ -d /tmp ]; then",
          "ls /tmp",
          "fi",
         );
($err) = $obj->run();

print "ERROR: $err\n";

