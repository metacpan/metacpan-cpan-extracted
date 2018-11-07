#!/usr/bin/perl

if (! @ARGV) {
   die "usage: ssh-parallel-run.pl HOST HOST ...\n";
}

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->options("echo" => "echo");
$obj->options("mode" => "script");
$obj->options("ssh_num" => 5);
$obj->cmd(q(echo "Dollar \$ Backtick \` Backslash \\\\ Quote \\""));
$obj->cmd("hostname");
$obj->ssh(@ARGV);

foreach my $host (@ARGV) {
   print "#############################\n";
   print "# $host\n";
   print "#############################\n";

   @tmp = $obj->output('host' => $host, 'output' => 'stdout', 'command' => 'all');

   foreach my $tmp (@tmp) {
      print join("\n",@$tmp,'');
   }
}
