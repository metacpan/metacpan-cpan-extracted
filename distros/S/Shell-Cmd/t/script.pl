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

our($cwd,$ret,@ssh_hosts);

sub testScript {
   my (@opts) = @_;
   my $test    = $0;
   $test       =~ s,^.*/,,;
   $test       =~ s/\.t$//;
   my @t       = split(/\-/,$test);
   my $ssh     = ($t[0] =~ /s$/ ? 1 : 0);
   my $script  = $t[1];
   my $testdir = $::ti->testdir();
   $testdir    = `cd $testdir; pwd`;
   die "Problem with test directory '$testdir', \$?=$?" if $?;
   chomp($testdir);

   if ($ssh) {
      if (! $ENV{'SSH_TESTING'}) {
         $::ti->skip_all("SSH testing disabled.  Set SSH_TESTING to a list of hosts to enable.");
         return;
      }
      @ssh_hosts = split(/\s+/,$ENV{'SSH_TESTING'});
   }

   ##
   ## Create the object and add the commands from the script
   ##

   $cwd = `pwd;`;
   chomp($cwd);

   my @cmds    = _parseScript($script,$testdir);

   my $obj     = new Shell::Cmd;
   $ret        = '';

   my %runopts;
   my $tmp_script;
   my $ssh_num = 1;
   my $tmp_script_keep;

   while (@opts) {
      my $opt = shift(@opts);
      my $val = shift(@opts);

      if ($opt eq 'env') {
         $obj->env(@$val);

      } elsif ($opt eq 'RUN') {
         my($o,$v) = split(/=/,$val);
         $runopts{$o} = $v;

      } elsif ($opt eq 'SSH_no_hosts') {
         @ssh_hosts = ();

      } elsif ($opt eq 'ssh_num') {
         $ssh_num   = $val;

      } elsif ($opt eq 'tmp_script') {
         $tmp_script = $val;
      } elsif ($opt eq 'tmp_script_keep') {
         $tmp_script_keep = $val;

      } else {
         my $err = $obj->options($opt,$val);

         if ($err) {
            $::ti->skip_all("Invalid script option: $opt");
         }
      }
   }

   my @args;
   if (defined($tmp_script)) {
      push(@args,'tmp_script',$tmp_script);
   } else {
      push(@args,'tmp_script',"$testdir/$test.sh");
   }
   if (defined($tmp_script_keep)) {
      push(@args,'tmp_script_keep',$tmp_script_keep);
   } else {
      push(@args,'tmp_script_keep',1);
   }
   $obj->options(@args);

   while (@cmds) {
      my $cmd  = shift(@cmds);
      my $opts = shift(@cmds);
      my %opts = %$opts;
      my @o    = keys(%opts);
      my $err;

      if (@o) {
         $err  = $obj->cmd($cmd,$opts);
      } else {
         $err  = $obj->cmd($cmd);
      }

      if ($err) {
         $::ti->skip_all("Invalid command or option: $cmd");
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

   # For SSH, we need to add some support for multiple hosts.
   # A block of <HOST>...</HOST> will be repeated once for each
   # host.

   if ($ssh) {
      my $in  = new IO::File;
      my $out = new IO::File;
      $in->open("$testdir/$test.exp0");
      $out->open("> $testdir/$test.exp0s");
      my @in = <$in>;
      chomp(@in);

      while (@in) {
         my $line = shift(@in);
         if ($line eq "<HOST>") {
            my @tmp;
            while (@in) {
               my $l = shift(@in);
               last  if ($l eq "</HOST>");
               push(@tmp,$l);
            }
            foreach my $host (@ssh_hosts) {
               foreach my $l (@tmp) {
                  my $t = $l;
                  $t =~ s/HOST/$host/g;
                  print $out "$t\n";
               }
            }
         } else {
            print $out "$line\n";
         }
      }

      $in->close;
      $out->close;

      $obj->options('ssh_num'    => $ssh_num,
                    'ssh_script' => "/tmp/ssh_cmd_$$.sh",
                   );
   }

   ##
   ## Now run it
   ##

   if ($mode eq 'run') {
      _set_runopts($obj,%runopts);
      if ($ssh) {
         $::ti->file(\&_runRun_ssh,'','',"$test.exp0s",'',$obj);
      } else {
         $::ti->file(\&_runRun,'','',"$test.exp0",'',$obj);
      }
   } elsif ($mode eq 'script') {
      _set_runopts($obj,%runopts);
      if ($ssh) {
         $obj->ssh();
      } else {
         $obj->run();
      }
      return $obj;
   } else {
      $::ti->file(\&_dryRun,'','',"$test.exp0",'',$obj);
   }
   $::ti->done_testing();
   rename("$testdir/tmp_test_inter","$testdir/$test.out");
   if (! $ENV{TI_NOCLEAN}) {
      unlink("$testdir/$test.out");
      unlink("$testdir/$test.exp0");
      unlink("$testdir/$test.sh");
   }
}

sub _set_runopts {
   my($obj,%runopts) = @_;
   foreach my $opt (keys %runopts) {
      my @path = split(/\//,$opt);
      my $ele  = pop(@path);
      my $val  = $runopts{$opt};
      my $ptr  = $obj;
      while (@path) {
         my $p = shift(@path);
         $ptr  = $$ptr{$p};
      }
      $$ptr{$ele} = $val;
   }
}

sub testScriptMode {
   my(@args) = @_;

   $::obj->output(@args);
}

sub _runRun_ssh {
   my($output,$obj) = @_;

   my($stdout,$stderr,$exit) = capture {
      $obj->ssh(@ssh_hosts);
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
   if (@ssh_hosts) {
      $script = $obj->ssh(@ssh_hosts);
   } else {
      $script = $obj->run();
   }
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

