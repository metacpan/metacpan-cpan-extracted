#!/usr/bin/perl -w

# This takes arguments:
#    (TEST_INTER_OBJECT, SCRIPT_FILE, TEST_LABEL, TEST_DIR,
#     OPT1 => VAL1, OPT2 => VAL2 ...)
# and turns it into a Shell::Cmd object and runs it based on the options.
#
# It uses the following files:
#    SCRIPT_FILE.scr          a text script
#    TEST_LABEL.exp           the expected output (raw)
#    TEST_LABEL.exp0          the expected output (corrected)
#    TEST_LABEL.sh            the script produced
#    TEST_LABEL.out           the actual output

use Shell::Cmd;
use IO::File;
use Capture::Tiny qw(capture);

our($cwd,$ret);

sub testScript {
   my ($ti,$script,$test,$testdir,@opts) = @_;
   $test   =~ s/\.t$//;
   $testdir=`cd $testdir; pwd`;
   chomp($testdir);

   ##
   ## Create the object and add the commands from the script
   ##

   $cwd = `pwd;`;
   chomp($cwd);

   my @cmds    = _parseScript($script,$testdir);

   my $obj     = new Shell::Cmd;
   $ret        = '';

   while (@opts) {
      my $opt = shift(@opts);
      my $val = shift(@opts);

      if ($opt eq 'env') {
         $obj->env(@$val);

      } else {
         my $err = $obj->options($opt,$val);

         if ($err) {
            $ti->skip_all("Invalid script option: $opt");
         }
      }
   }

   $obj->options('tmp_script',"$testdir/$test.sh",'tmp_script_keep',1);

   while (@cmds) {
      my $cmd  = shift(@cmds);
      my $opts = shift(@cmds);

      my $err  = $obj->cmd($cmd,$opts);

      if ($err) {
         $ti->skip_all("Invalid command option: $cmd");
         return;
      }
   }

   my $mode = $obj->mode();

   ##
   ## Fix the directories in the script and expected outputs
   ##

   if ($mode ne 'script') {
      my $in  = new IO::File;
      my $out = new IO::File;
      $in->open("$testdir/$test.exp");
      $out->open("> $testdir/$test.exp0");
      my @in = <$in>;
      foreach my $line (@in) {
         $line =~ s/TESTDIR/$testdir/g;
         $line =~ s/CURRDIR/$cwd/g;
         print $out $line;
      }
      $in->close;
      $out->close;
   }

   ##
   ## Now run it
   ##

   if ($mode eq 'run') {
      $ti->file(\&_runRun,'','',"$test.exp0",'',$obj);
   } elsif ($mode eq 'script') {
      $obj->run();
      return $obj;
   } else {
      $ti->file(\&_dryRun,'','',"$test.exp0",'',$obj);
   }
   $ti->done_testing();
   rename("$testdir/tmp_test_inter","$testdir/$test.out");
   if (! $ENV{TI_NOCLEAN}) {
      unlink("$testdir/$test.out");
      unlink("$testdir/$test.exp0");
      unlink("$testdir/$test.sh");
   }
}

sub testScriptMode {
   my(@args) = @_;

   $::obj->output(@args);
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

   my $script = $obj->run();
   my $out = new IO::File;
   $out->open(">$output");
   print $out $script,"\n";
   $out->close();
}

sub _parseScript {
   my($test,$testdir) = @_;

   open(IN,"$testdir/scr/$test.scr");
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

      my($cmd,$opts,%opts);
      if ($line =~ /^(.+?)\s*#OPTS\s*(.+)$/) {
         ($cmd,$opts) = ($1,$2);
      } else {
         ($cmd,$opts) = ($line,'');
      }

      if ($cmd =~ /^\[\s*(.*?)\s*\]$/) {
         my $tmp = $1;
         my @tmp = split(/\s*,\s*/,$tmp);
         $cmd    = [@tmp];
      }

      while ($opts) {
         $opts    =~ s/^(\S*)\s+//;
         my $opt  = $1;
         my $val;
         if ($opts =~ s/^'([^']*)'\s*//) {
            $val  = $1;
         } else {
            $opts =~ s/^(\S*)\s*//;
            $val  = $1;
         }
         $opts{$opt} = $val;
      }
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

