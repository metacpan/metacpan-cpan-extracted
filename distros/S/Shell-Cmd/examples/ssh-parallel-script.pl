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
@out = $obj->ssh(@ARGV);

foreach my $host (@ARGV) {
   print "#############################\n";
   print "# $host\n";
   print "#############################\n";
   $tmp = shift(@out);
   @tmp = @$tmp;
   shift(@tmp);

   while (@tmp) {
      my ($cmd_num,$status,@alt) = @{ shift(@tmp) };
      foreach my $alt (@alt) {
         my($cmd,$exit,$stdout,$stderr) = @$alt;
         print "# $cmd\n";
         print "# STDOUT\n";
         print join("\n",@$stdout),"\n";
         print "# STDERR\n";
         print join("\n",@$stderr),"\n";
         print "\n";
      }
   }
}
