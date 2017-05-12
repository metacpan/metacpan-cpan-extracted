#!/usr/bin/perl -w

# This takes arguments:
#    (TEST_INTER_OBJECT TEST OPT1 VAL1 OPT2 VAL2 ...)
#
# It reads a script in:
#    TEST.scr
#
# and turns it into a Shell::Cmd object and runs it based on the options.

use Shell::Cmd;
use IO::File;
use Capture::Tiny qw(capture);

our($cwd,$ret,$tmpscript);

sub testScript {
   my ($ti,$file,$test,$testdir,@opts) = @_;
   $cwd = `pwd;`;
   chomp($cwd);

   my @cmds    = _parseScript($file,$testdir);

   my $obj     = new Shell::Cmd;
   $ret        = '';
   $tmpscript  = 1;

   while (@opts) {
      my $opt = shift(@opts);
      my $val = shift(@opts);

      if ($opt eq 'return') {
         $ret = $val;
      } elsif ($opt eq 'noscript') {
         $tmpscript = 0;

      } elsif ($opt eq 'env') {
         $obj->env(@$val);

      } else {
         my $err = $obj->options($opt,$val);

         if ($err) {
            $ti->skip_all("Invalid script option: $opt");
         }
      }
   }

   while (@cmds) {
      my $cmd  = shift(@cmds);
      my $opts = shift(@cmds);

      my $err  = $obj->cmd($cmd,$opts);

      if ($err) {
         $ti->skip_all("Invalid command option: $cmd");
         return;
      }
   }

   ###

   # Fix the expected output.
   my $in  = new IO::File;
   my $out = new IO::File;
   $in->open("$testdir/$file-$test.exp");
   $out->open("> $testdir/$file-$test.exp0");
   my @in = <$in>;
   foreach my $line (@in) {
      $line =~ s/TESTDIR/$testdir/g;
      $line =~ s/CURRDIR/$cwd/g;
      print $out $line;
   }
   $in->close;
   $out->close;

   ###

   $obj->options('tmp_script',"$testdir/$file-$test.sh",'tmp_script_keep',1)
      if ($tmpscript);

   my $mode = $obj->mode();

   if ($mode eq 'run') {
      $ti->file(\&_runRun,'','',"$file-$test.exp0",'',$obj);
   } elsif ($mode eq 'script') {
      $ti->file(\&_scrRun,'','',"$file-$test.exp0",'',$obj);
   } else {
      $ti->file(\&_dryRun,'','',"$file-$test.exp0",'',$obj);
   }
   $ti->done_testing();
   rename("$testdir/tmp_test_inter","$testdir/$file-$test.out");
   if (! $ENV{TI_NOCLEAN}) {
      unlink("$testdir/$file-$test.out");
      unlink("$testdir/$file-$test.exp0");
      unlink("$testdir/$file-$test.sh");
   }
}

sub _scrRun {
   my($output,$obj) = @_;
   my @out = $obj->run();

   my $out = new IO::File;
   $out->open(">$output");

   my $tmp = shift(@out);
   print $out "FAILED: $tmp\n";

   foreach my $cmd (@out) {

      my ($num,$status,@alt) = @$cmd;
      print $out "CMD: $num [ $status ]\n";

      foreach my $alt (@alt) {
         my($c,$exit,$stdout,$stderr) = @$alt;
         print $out "ALT [$exit]: $c\n";
         print $out "STDOUT:\n";
         print $out join("\n",@$stdout),"\n";
         print $out "STDERR:\n";
         print $out join("\n",@$stderr),"\n";
      }
   }
   $out->close();
}

sub _runRun {
   my($output,$obj) = @_;

   my($stdout,$stderr,$exit) = capture {
      $obj->run();
   };
   $exit = $exit >> 8;

   my $out = new IO::File;
   $out->open(">$output");
   print $out $stdout,"\n";
   print $out "###STDERR\n";
   print $out $stderr,"\n";
   print $out "###EXIT\n";
   print $out "$exit\n";
   $out->close();
}

sub _dryRun {
   my($output,$obj) = @_;

   my $script;
   if ($ret eq 'scalar') {
      $script = $obj->run();
   } else {
      ($script) = $obj->run();
   }
   my $out = new IO::File;
   $out->open(">$output");
   print $out $script,"\n";
   $out->close();
}

sub _parseScript {
   my($test,$testdir) = @_;

   open(IN,"$testdir/$test.scr");
   my @in = <IN>;
   close(IN);
   chomp(@in);

   my(@cmd,@opts,@ret);

   LINE:
   foreach $line (@in) {

      #
      # Replace TESTDIR
      # Strip leading/trailing spaces and comments
      # Remove blank lines
      #

      $line =~ s/TESTDIR/$testdir/g;
      $line =~ s/CURRDIR/$cwd/g;
      $line =~ s/^\s*//;
      $line =~ s/\s*$//;
      next LINE  if (! $line  ||  $line =~ /^#/);

      #
      # A line is either a simple command, or a command followed by
      # a string '#OPTS' followed by a list of options.  Options must
      # be a space separated list of OPT VAL pairs suitable for passing
      # in as a per-command option.
      #

      my($cmd,$opts);
      if ($line =~ /^(.+?)\s*#OPTS\s*(.+)$/) {
         ($cmd,$opts) = ($1,$2);
      } else {
         ($cmd,$opts) = ($line,'');
      }
      my %opts = split(/\s+/,$opts);

      push(@ret,$cmd,\%opts);
   }

   return @ret;
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:

