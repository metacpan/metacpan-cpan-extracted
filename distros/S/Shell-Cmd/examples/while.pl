#!/usr/bin/perl

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->options("mode" => "run");
$obj->cmd('i=1',
          'while [ $i -ne 3 ]; do',
          'echo $i',
          'i=`expr $i + 1`',
          'done',
         );
($err) = $obj->run();

print "ERROR: $err\n";

