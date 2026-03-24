#!/usr/bin/perl

use Shell::Cmd;
$obj = new Shell::Cmd;
$obj->cmd(q(echo -e "This is command 1 line 1\nThis is command 1 line 2"));
$obj->cmd(q(echo -e "This is command 2 line 1\nThis is command 2 line 2" >&2));
$obj->mode('script');
$obj->run();

my @out;

foreach my $cmd (1..2) {
   foreach my $out (qw(command exit stdout stderr)) {
      @out = $obj->output('output' => $out, 'command' => $cmd);
      print "#### CMD $cmd $out\n";
      foreach my $inst (@out) {
         my @line = @$inst;
         foreach my $line (@line) {
            print "$line\n";
         }
      }
      print "\n";
   }
}
