package Shell::Cmd;
# Copyright (c) 2013-2017 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

require 5.008;
use warnings 'all';
use strict;
use Capture::Tiny qw(capture capture_stdout capture_stderr);
use Net::OpenSSH;
use Parallel::ForkManager 0.7.6;
use IO::File;
use Cwd;

our($VERSION);
$VERSION = "2.13";

$| = 1;

###############################################################################
# METHODS
###############################################################################

sub version {
  my($self) = @_;
  return $VERSION;
}

sub new {
   my($class,%options) = @_;

   my $self = {};

   bless $self,$class;
   $self->flush();

   return $self;
}

sub flush {
   my($self, @opts)   = @_;
   $self->_init_cache();

   my $all            = 1  if (! @opts);
   my %opts           = map { $_,1 } @opts;

   $$self{'err'}      = '';

   $$self{'dire'}     = '.'       if ($all  ||  $opts{'dire'});

   # [ [VAR, VAL], [VAR, VAL], ... ]
   $$self{'env'}      = {}        if ($all  ||  $opts{'env'});

   if ($all  ||  $opts{'opts'}) {
      $$self{'mode'}            = 'run';
      $$self{'output'}          = 'both';
      $$self{'f-output'}        = 'both';
      $$self{'script'}          = '';
      $$self{'echo'}            = 'noecho';
      $$self{'failure'}         = 'exit';

      $$self{'tmp_script'}      = '';
      $$self{'tmp_script_keep'} = 0;
      $$self{'ssh_script'}      = '';
      $$self{'ssh_script_keep'} = 0;

      $$self{'ssh_opts'}        = {};
      $$self{'ssh_num'}         = 1;
      $$self{'ssh_sleep'}       = 0;
   }

   # [ [CMD, %OPTS], [CMD, %OPTS], ... ]
   $$self{'cmd'}      = []        if ($all  ||  $opts{'commands'});

   return;
}

###############################################################################

sub dire {
   my($self,$dire) = @_;
   return $$self{'dire'}  if (! defined($dire));

   return $self->options("dire",$dire);
}

sub mode {
   my($self,$mode) = @_;
   return $$self{'mode'}  if (! defined($mode));

   return $self->options("mode",$mode);
}

sub env {
   my($self,@tmp) = @_;

   if (! @tmp) {
      my @ret;
      foreach my $key (sort keys %{ $$self{'env'} }) {
         push(@ret,$key,$$self{'env'}{$key});
      }
      return @ret;
   }

   while (@tmp) {
      my $var = shift(@tmp);
      my $val = shift(@tmp);
      $$self{'env'}{$var} = $val;
   }

   return;
}

sub options {
   my($self,%opts) = @_;

   OPT:
   foreach my $opt (keys %opts) {

      my $val = $opts{$opt};
      $opt    = lc($opt);

      if ($opt eq 'mode') {

         if (lc($val) =~ /^(run|dry-run|script)$/) {
            $$self{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt eq 'dire') {
         $$self{$opt} = $val;
         next OPT;

      } elsif ($opt eq 'output'  ||  $opt eq 'f-output') {

         if (lc($val) =~ /^(both|merged|stdout|stderr|quiet)$/) {
            $$self{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt eq 'script') {

         if (lc($val) =~ /^(run|script|simple)$/) {
            $$self{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt eq 'echo') {

         if (lc($val) =~ /^(echo|noecho|failed)$/) {
            $$self{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt eq 'failure') {

         if (lc($val) =~ /^(exit|display|continue)$/) {
            $$self{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt =~ s/^ssh://) {
         $$self{'ssh_opts'}{$opt} = $val;
         next OPT;

      } elsif ($opt eq 'ssh_num'    ||
               $opt eq 'ssh_sleep'
              ) {
         $$self{$opt} = $val;
         next OPT;

      } elsif ($opt eq 'tmp_script'       ||
               $opt eq 'tmp_script_keep'  ||
               $opt eq 'ssh_script'       ||
               $opt eq 'ssh_script_keep'
              ) {
         $$self{$opt} = $val;
         next OPT;

      } else {
         $self->_print(1,"Invalid option: $opt");
         return 1;
      }

      $self->_print(1,"Invalid value: $opt [ $val ]");
      return 1;
   }

   return 0;
}

###############################################################################

sub cmd {
   my($self,@args) = @_;

   while (@args) {
      my $cmd  = shift(@args);
      if (ref($cmd) ne ''  &&
          ref($cmd) ne 'ARRAY') {
         $$self{'err'} = "cmd must be a string or listref";
         $self->_print(1,$$self{'err'});
         return 1;
      }

      my %options;
      if (@args  &&  ref($args[0]) eq 'HASH') {
         %options = %{ shift(@args) };
      }

      foreach my $opt (keys %options) {
         if ($opt !~ /^(dire|flow|noredir|retry|sleep|check)$/) {
            $$self{'err'} = "Invalid cmd option: $opt";
            $self->_print(1,$$self{'err'});
            return 1;
         }
      }

      push @{ $$self{'cmd'} },[$cmd,%options];
   }
   return 0;
}

###############################################################################

# Construct and run or print the script.
#
sub run {
   my($self)   = @_;
   my ($script,$stdout,$stderr) = $self->_script();

   #
   # Print out the script if this is a dry run.
   #

   if ($$self{'mode'} eq 'dry-run') {
      $script .= "\n";
      if (wantarray) {
         return ($script);
      }
      return $script;
   }

   #
   # If it's running in real-time, do so.
   #

   my $tmp_script = $$self{'tmp_script'};
   if ($tmp_script) {
      my $out = new IO::File;

      if ($out->open("> $tmp_script")) {
         print $out $script;
         $out->close();
         $script = ". $tmp_script";
      } else {
         my $err = -2;
         if (wantarray) {
            return ($err);
         }
         return $err;
      }
   }

   my $err;
   if ($$self{'mode'} eq 'run') {
      system("$script");
      $err = $?;

      if ($tmp_script  &&
          ! $$self{'tmp_script_keep'}) {
         unlink($tmp_script);
      }

      if (wantarray) {
         return ($err);
      }
      return $err;
   }

   #
   # If it's running in 'script' mode, capture the output so that
   # we can parse it.
   #

   my($capt_out,$capt_err,$capt_exit);

   if      ($stdout  &&  $stderr) {
      ($capt_out,$capt_err,$capt_exit) = capture        { system( "$script" ) };
   } elsif ($stdout) {
      ($capt_out,$capt_exit)           = capture_stdout { system( "$script" ) };
   } elsif ($stderr) {
      ($capt_err,$capt_exit)           = capture_stderr { system( "$script" ) };
   } else {
      system("$script");
      $capt_exit = $?;
   }
   $capt_exit = $capt_exit >> 8;

   if ($tmp_script  &&
       ! $$self{'tmp_script_keep'}) {
      unlink($tmp_script);
   }

   #
   # Parse the output and return it.
   #

   return $self->_script_output($capt_out,$capt_err,$capt_exit);
}

###############################################################################

sub ssh {
   my($self,@hosts) = @_;

   if (! @hosts) {
      $self->_print(1,"A host or hosts must be supplied with the ssh method");
      return 1;
   }

   my ($script,$stdout,$stderr) = $self->_script();

   #
   # Print out the script if this is a dry run.
   #

   if ($$self{'mode'} eq 'dry-run') {
      $script .= "\n";
      $script  = $self->_quote($script);

      my @ret;
      foreach my $host (@hosts) {
         push @ret, "##########################\n" .
                    "ssh $host \"$script\"\n\n";
      }
      return @ret;
   }

   #
   # Run the script on each host.
   #

   my $tmp_script = $$self{'tmp_script'};
   if ($tmp_script) {
      my $f   = $$self{'ssh_script'}  ||  $tmp_script;
      my $out = new IO::File;

      if ($out->open("> $tmp_script")) {
         print $out $script;
         $out->close();
         $script = ". $f";

      } else {
         my $err = -2;
         if (wantarray) {
            return ($err);
         }
         return $err;
      }
   }

   if ($$self{'ssh_num'} == 1) {
      return $self->_ssh_serial($script,$stdout,$stderr,@hosts);
   } else {
      return $self->_ssh_parallel($script,$stdout,$stderr,@hosts);
   }
}

sub _ssh_serial {
   my($self,$script,$stdout,$stderr,@hosts) = @_;
   my @ret;

   foreach my $host (@hosts) {
      push @ret, $self->_ssh($script,$stdout,$stderr,$host);
   }

   return @ret;
}

sub _ssh_parallel {
   my($self,$script,$stdout,$stderr,@hosts) = @_;
   my @ret;

   my $max_proc = ($$self{'ssh_num'} ? $$self{'ssh_num'} : @hosts);
   my $manager = Parallel::ForkManager->new($max_proc);

   $manager->run_on_finish
     (
      sub {
         my($pid,$exit_code,$id,$signal,$core_dump,$data) = @_;
         my $n    = shift(@$data);
         $ret[$n] = $data;
      }
     );

   for (my $i=0; $i<@hosts; $i++) {
      my $host = $hosts[$i];

      $manager->start and next;

      my @r = ($i);
      push @r, $self->_ssh($script,$stdout,$stderr,$host);

      $manager->finish(0,\@r);
   }

   $manager->wait_all_children();
   return @ret;
}

sub _ssh {
   my($self,$script,$stdout,$stderr,$host) = @_;

   my $ssh = Net::OpenSSH->new($host, %{ $$self{'ssh_opts'} });

   if ($$self{'tmp_script'}) {
      my $f1 = $$self{'tmp_script'};
      my $f2 = $$self{'ssh_script'}  ||  $f1;
      $ssh->scp_put($f1,$f2)  or
        return (-3);
   }

   #
   # If we're sleeping, do so.
   #

   if ($$self{'ssh_sleep'}) {
      sleep(int(rand($$self{'ssh_sleep'})));
   }

   #
   # If it's running in real-time, do so.
   #

   my $f   = $$self{'ssh_script'}  ||  $$self{'tmp_script'};

   if ($$self{'mode'} eq 'run') {
      $ssh->system({},$script);
      my $ret = $?;

      if (! $$self{'ssh_script_keep'}) {
         $ssh->system({},"rm -f $f");
      }
      return ($ret);
   }

   #
   # If it's running in 'script' mode, capture the output so that
   # we can parse it.
   #

   my($capt_out,$capt_err,$capt_exit);

   if      ($stderr) {
      ($capt_out,$capt_err) = $ssh->capture2({},$script);
      $capt_exit            = $?;
   } elsif ($stdout) {
      $capt_out             = $ssh->capture({},$script);
      $capt_exit            = $?;
   } else {
      $ssh->system({},$script);
      $capt_exit            = $?;
   }
   $capt_exit = $capt_exit >> 8;

   if (! $$self{'ssh_script_keep'}) {
      $ssh->system({},"rm -f $f");
   }

   #
   # Parse the output and return it.
   #

   return $self->_script_output($capt_out,$capt_err,$capt_exit);
}

###############################################################################
###############################################################################

# Some hashes to make some operations cleaner
my(%keep_stdout,%keep_stderr,%succ_status,%fail_status);
BEGIN {
   %keep_stdout = map { $_,1 } qw(both merged stdout);
   %keep_stderr = map { $_,1 } qw(both stderr);
   %succ_status = map { $_,1 } qw(succ retried);
   $succ_status{''} = 1;
   %fail_status = map { $_,1 } qw(exit fail);
}

sub _init_cache {
   my($self) = @_;

   $$self{'c'} =
     {
      #
      # Script indentation
      #
      'ind_per_lev'    => 3,
      'ind_cur_lev'    => 0,
      'curr_ind'       => "",
      'next_ind'       => "",
      'prev_ind'       => "",

      # The simple script
      #   ( SIMPLE_CMD_DESC1, SIMPLE_CMD_DESC2, ... )
      # where:
      #   SIMPLE_CMD_DESC = { 'num'       => CMD_NUM,
      #                       'flow'      => FLOW,
      #                       'flow_type' => FLOW_TYPE,
      #                       'opts'      => OPTS,
      #                       'cmd'       => CMD,
      #                     }
      #   CMD_NUM         : the number of this command
      #   FLOW            : '', if, else, ...  (the actual flow command or empty)
      #   FLOW_TYPE       : 'open', 'cont', or 'close'
      #   OPTS            : a hash of options for this command
      #   CMD             : a string containing a command alternative or a listref
      #                     of alternates
      #
      'simple'         => [],

      # Keep track of current flow structure
      #   ( [ FLOW_COMMAND, CMD_NUM ], [ FLOW_COMMAND, CMD_NUM ], ... )
      # where:
      #   FLOW_COMMAND    : if, while, ... (the opening command)
      #   CMD_NUM         : the number of the opening command
      #
      'flow'           => [],

      # Global options
      #   g_run        How the script is run:         dry-run, run, script
      #   g_type       The type of script to create:  run, script, simple
      #   g_echo       If we want to echo commands:   0/1
      #   g_fail       How to handle failure:         exit, display, continue
      #   g_redir      String to redirect output
      #   g_out        Capture STDOUT
      #   g_err        Capture STDERR
      #   g_output     The output option
      #   g_foutput    The f-output option
      'g_run'          => '',
      'g_type'         => '',
      'g_echo'         => '',
      'g_fail'         => '',
      'g_redir'        => '',
      'g_out'          => '',
      'g_err'          => '',
      'g_output'       => '',
      'g_foutput'      => '',

      # Command options
      #   c_meta       A meta command (supplied by this module) that does not
      #                need to be wrapped in error traps, retries, etc.
      #   c_num        The number of the current command
      #   c_flow       The flow command being processed (if, elif, while, ...)
      #   c_flow_type  The type of flow command (open, cont, close)
      #   c_retries    The number of retries
      #   c_sleep      How long to sleep between retries
      #   c_noredir    1 if this command should not be redirected
      #   c_check      The command to check success

      'c_meta'         => '',
      'c_num'          => '',
      'c_flow'         => '',
      'c_flow_type'    => '',
      'c_retries'      => '',
      'c_sleep'        => '',
      'c_noredir'      => '',
      'c_check'        => '',

     };
}

# Variables used in scripts
#   SC_ORIG_DIRE     : the directory you are in when the script ran
#   SC_DIRE          : the working directory of the script
#   SC_FAILED = N    : the command which failed (0 = none, 1 = script
#                      initialization, 2+ = command N)
#                      Unused in simple scripts
#   SC_EXIT          : the exit code for the script
#   SC_CURR_EXIT     : the exit code for the current command
#   SC_CURR_SUCC     : 1 if the current command (any alternate) succeeded
#   SC_RETRIES = N   : this command will run up to N times
#   SC_TRY = N       : we're currently on the Nth try

#####################
# This creates the script and it is ready to be printed or evaluated
# in double quotes.
#
sub _script {
   my($self)  = @_;
   $self->_script_options();

   # First, generate the simple script.  This contains the basic commands
   # that will run.  Then we'll flesh it out with options in the second
   # step.

   $$self{'c'}{'c_num'} = 1;
   push @{ $$self{'c'}{'simple'} }, $self->_simple_init();
   $$self{'c'}{'c_num'}++;

   foreach my $ele (@{ $$self{'cmd'} }) {
      my($cmd,%options) = @$ele;
      push @{ $$self{'c'}{'simple'} }, $self->_simple_cmd($cmd,%options);
      $$self{'c'}{'c_num'}++;
   }
   return ()  if ($$self{'err'});

   push @{ $$self{'c'}{'simple'} }, $self->_simple_term();

   # Now generate the actual script.

   my @script;
   push @script, $self->_simple_script();

   # If we want to generate a simple script, we're done.

   if ($$self{'c'}{'g_type'} eq 'simple') {
      my $script = join("\n",@script);
      return ($script,$$self{'c'}{'g_out'},$$self{'c'}{'g_err'});
   }

   # Generate the rest of a full script

   push @script, $self->_script_init();

   #
   # Handle each command.
   #

   foreach my $tmp (@{ $$self{'c'}{'simple'} }) {
      next           if (! $$tmp{'cmd'});
      $$self{'c'}{'c_num'}       = $$tmp{'num'};
      $$self{'c'}{'c_flow'}      = $$tmp{'flow'};
      $$self{'c'}{'c_flow_type'} = $$tmp{'flow_type'};
      my $options    = $$tmp{'opts'};
      my @cmd        = (ref($$tmp{'cmd'}) ? @{ $$tmp{'cmd'} } : ($$tmp{'cmd'}));

      if ($$self{'c'}{'c_flow'}) {
         push @script, $self->_flow(@cmd);
      } else {
         push @script, $self->_cmd($options,@cmd);
      }
   }

   #
   # Form the script.
   #

   push @script, $self->_script_term();
   my $script = join("\n",@script);

   return ()  if ($$self{'err'});
   return ($script,$$self{'c'}{'g_out'},$$self{'c'}{'g_err'});
}

#####################
# Generate the simple script

sub _simple_init {
   my($self)  = @_;
   my @script;

   my %cmd    = ('num'       => $$self{'c'}{'c_num'},
                 'flow'      => '',
                 'flow_type' => '',
                );

   #
   # Keep track of our starting directory.
   #

   push @script, { %cmd,
                   'opts' => { 'sc'  => 1 },
                   'cmd'  => qq(SC_ORIG_DIRE=`pwd`),
                 };

   #
   # Handle environment variables.
   #
   #   ENV_VAR=VAL
   #   export ENV_VAR
   #

   my @env = sort keys %{ $$self{'env'} };
   if (@env) {
      my @var;
      foreach my $var (@env) {
         my $val       = $$self{'env'}{$var};
         $val          = $self->_quote($val);
         push @script, { %cmd,
                         'opts' => { 'sc'  => 1 },
                         'cmd'  => qq($var="$val"),
                       };
         push(@var,$var);
      }
      my $vars = join(' ',@var);
      push @script, { %cmd,
                      'opts' => { 'sc'  => 1 },
                      'cmd'  => qq(export $vars),
                    };
   }

   #
   # If we specify a global dire option, handle that now.
   #

   if ($$self{'dire'}  &&  $$self{'dire'} ne '.') {
      my $dire = $self->_quote($$self{'dire'});
      push @script, { %cmd,
                      'opts' => { 'sc'  => 1 },
                      'cmd'  => qq(SC_DIRE="$dire"),
                    },
                    { %cmd,
                      'opts' => {},
                      'cmd'  => qq(cd "\$SC_DIRE"),
                    };
   } else {
      push @script, { %cmd,
                      'opts' => { 'sc'  => 1 },
                      'cmd'  => qq(SC_DIRE=`pwd`),
                    };
   }

   return @script;
}

sub _simple_term {
   my($self)  = @_;
   my @script;

   my %cmd    = ('num'       => $$self{'c'}{'c_num'},
                 'flow'      => '',
                 'flow_type' => '',
                 'opts'      => { 'sc'  => 1 },
                );
   my @cmd;

   #
   # Make sure we end up in the original directory.
   #

   push(@cmd, qq(cd "\$SC_ORIG_DIRE"));

   foreach my $cmd (@cmd) {
      push @script, { %cmd,
                      'cmd' => $cmd,
                    }
   }
   return @script;
}

#####################
# Add each simple command

sub _simple_cmd {
   my($self,$cmd,%options) = @_;
   my @script;

   my %cmd    = ('num'       => $$self{'c'}{'c_num'},
                 'opts'      => {},
                );

   #
   # Check to see if it is a flow command
   #

   my $flow = '';
   my $type = '';

   if (! ref($cmd)) {

      # if, elif, else, fi
      if      ($cmd =~ /^\s*(if)\s+.*?;\s*then\s*$/   ||
               $cmd =~ /^\s*(elif)\s+.*?;\s*then\s*$/ ||
               $cmd =~ /^\s*(else)\s*$/               ||
               $cmd =~ /^\s*(fi)\s*$/) {
         $flow = $1;

         if ($flow eq 'if') {
            push(@{ $$self{'c'}{'flow'} },[$flow,$$self{'c'}{'c_num'}]);
            $type = 'open';

         } else {
            if (! @{ $$self{'c'}{'flow'} }  ||
                $$self{'c'}{'flow'}[$#{ $$self{'c'}{'flow'} }][0] ne 'if') {
               $$self{'err'} =
                 "Broken flow: 'fi' found, but no 'if': $$self{'c'}{'c_num'}";
               return ();
            }

            if ($flow eq 'fi') {
               $type = 'close';
               pop(@{ $$self{'c'}{'flow'} });
            } else {
               $type = 'cont';
            }
         }

      } elsif ($cmd =~ /^\s*(while)\s+.*?;\s*do\s*$/   ||
               $cmd =~ /^\s*(until)\s+.*?;\s*do\s*$/   ||
               $cmd =~ /^\s*(for)\s+.*?;\s*do\s*$/     ||
               $cmd =~ /^\s*(done)\s*$/) {
         $flow = $1;

         if ($flow eq 'while'  ||  $flow eq 'until'  ||  $flow eq 'for') {
            push(@{ $$self{'c'}{'flow'} },[$flow,$$self{'c'}{'c_num'}]);
            $type = 'open';
         } else {
            if (! @{ $$self{'c'}{'flow'} }  ||
                ($$self{'c'}{'flow'}[$#{ $$self{'c'}{'flow'} }][0] ne 'while'  &&
                 $$self{'c'}{'flow'}[$#{ $$self{'c'}{'flow'} }][0] ne 'until'  &&
                 $$self{'c'}{'flow'}[$#{ $$self{'c'}{'flow'} }][0] ne 'for')) {
               $$self{'err'} =
                 "Broken flow: 'done' found, but no 'while/until/for': $$self{'c'}{'c_num'}";
               return ();
            }

            $type = 'close';
            pop(@{ $$self{'c'}{'flow'} });
         }
      }
   }

   if ($flow) {
      push @script, { %cmd,
                      'flow'      => $flow,
                      'flow_type' => $type,
                      'opts'      => {},
                      'cmd'       => $cmd,
                    };
      return @script;
   }

   #
   # Now handle the other commands.
   #

   %cmd    = ('num'       => $$self{'c'}{'c_num'},
              'flow'      => '',
              'flow_type' => '',
             );

   #
   # Handle the per-command 'dire' option.
   #

   my $dire = '';
   if ($options{'dire'}  &&  $options{'dire'} ne '.') {
      $dire = $self->_quote($options{'dire'});
      push @script, { %cmd,
                      'opts'  => {},
                      'cmd'   => qq(cd "$dire";),
                    };
   }

   #
   # Handle the command.
   #

   push @script, { %cmd,
                   'opts'  => \%options,
                   'cmd'   => $cmd,
                 };

   #
   # Handle the per-command 'dire' option.
   #

   if ($dire) {
      push @script, { %cmd,
                      'opts'  => {},
                      'cmd'   => qq(cd "\$SC_DIRE";),
                    };
   }

   return @script;
}

#####################
# This will either generate a shell function that will print the simple
# script, or it will create the simple script itself.
#
# The shell function will be used to print the simple script only if
# 'failure' is set to display.
#
# The simple script will be generated only if we're doing a dry-run and
# producing a simple script.

sub _simple_script {
   my($self) = @_;
   my @script;
   return @script
     unless ($$self{'c'}{'g_fail'} eq 'display'  ||  $$self{'c'}{'g_type'} eq 'simple');
   my $curr_ind = $$self{'c'}{'curr_ind'};
   my $next_ind = $$self{'c'}{'next_ind'};
   my $prev_ind = $$self{'c'}{'prev_ind'};

   # A call to simple() prints out the simple script.  It will be
   # used only if a command failed, and the failure option is
   # display.

   if ($$self{'c'}{'g_fail'} eq 'display') {
      push @script,
        q[simple () {],
        q[   echo ""],
        q[   echo "#****************************************"],
        q[   echo "# The following script failed"],
        q[   while read line ;do],
        q[      loc=`echo "$line" | sed -e 's,:.*,,'`],
        q[      txt=`echo "$line" | sed -e 's,^[0-9]*:,,'`],
        q[      if [ "$SC_FAILED" = "$loc" ]; then],
        q[         echo "#*** Script failed in the following command"],
        q[      fi],
        q[      echo "$txt"],
        q[   done << EOF];

      $self->_ind_0();
      $curr_ind = $$self{'c'}{'curr_ind'};
      $next_ind = $$self{'c'}{'next_ind'};
      $prev_ind = $$self{'c'}{'prev_ind'};
   }

   foreach my $tmp (@{ $$self{'c'}{'simple'} }) {
      my $num     = $$tmp{'num'};
      my $pref    = ($$self{'c'}{'g_type'} eq 'simple' ? '' : "${num}:");
      my $flow    = $$tmp{'flow'};
      my $type    = $$tmp{'flow_type'};
      my $opts    = $$tmp{'opts'};
      my @cmd     = (ref($$tmp{'cmd'}) ? @{ $$tmp{'cmd'} } : ($$tmp{'cmd'}));

      if ($flow) {
         my ($cmd) = @cmd;
         if ($type eq 'open') {
            push @script,qq(${pref}${curr_ind}$cmd);
            $self->_ind_plus();
            $curr_ind = $$self{'c'}{'curr_ind'};
            $next_ind = $$self{'c'}{'next_ind'};
            $prev_ind = $$self{'c'}{'prev_ind'};
         } elsif ($type eq 'cont') {
            push @script,qq(${pref}${prev_ind}$cmd);
         } else {
            $self->_ind_minus();
            $curr_ind = $$self{'c'}{'curr_ind'};
            $next_ind = $$self{'c'}{'next_ind'};
            $prev_ind = $$self{'c'}{'prev_ind'};
            push @script,qq(${pref}${curr_ind}$cmd);
         }
         next;
      }

      my $cmd = shift(@cmd);
      push @script, qq(${pref}${curr_ind}$cmd);
      foreach my $c (@cmd) {
         push @script, qq(${pref}${curr_ind}# or),
                       qq(${pref}${curr_ind}# $c);
      }

      if ($$opts{'check'}) {
         my $c = $$opts{'check'};
         push @script, qq(${pref}${curr_ind}# Check with),
                       qq(${pref}${curr_ind}# $c);
      }
   }

   if ($$self{'c'}{'g_fail'} eq 'display') {
      push @script,
        q[EOF],
        q[}],
        q[];
   }

   return @script;
}

#####################
# Start the script.

sub _script_init {
   my($self) = @_;
   my @script;
   my $curr_ind = $$self{'c'}{'curr_ind'};
   my $next_ind = $$self{'c'}{'next_ind'};
   my $prev_ind = $$self{'c'}{'prev_ind'};

   #
   # Initialize the variable which tracks which command failed.
   #

   push @script, qq(${curr_ind}SC_FAILED=0;),
                 qq(${curr_ind}SC_EXIT=0;),
                 qq(${curr_ind}main () {);
   $self->_ind_plus();
   $curr_ind = $$self{'c'}{'curr_ind'};
   $next_ind = $$self{'c'}{'next_ind'};
   $prev_ind = $$self{'c'}{'prev_ind'};

   return @script;
}

sub _script_term {
   my($self) = @_;
   my @script;
   my $curr_ind = $$self{'c'}{'curr_ind'};
   my $next_ind = $$self{'c'}{'next_ind'};
   my $prev_ind = $$self{'c'}{'prev_ind'};

   $self->_ind_minus();
   $curr_ind = $$self{'c'}{'curr_ind'};
   $next_ind = $$self{'c'}{'next_ind'};
   $prev_ind = $$self{'c'}{'prev_ind'};
   push @script, qq(${curr_ind}}),
                 '',
                 qq(${curr_ind}main);

   # If failure = display, call simple with $SC_FAILED

   if ($$self{'c'}{'g_fail'} eq 'display') {
      push @script, qq(${curr_ind}if [ \$SC_FAILED -ne 0 ]; then),
                    qq(${next_ind}simple),
                    qq(${curr_ind}fi);
   }

   push @script, qq(${curr_ind}exit \$SC_EXIT;);

   return @script;
}

#####################
# Handle a command

sub _flow {
   my($self,$cmd) = @_;
   my @script = ('');
   my $curr_ind = $$self{'c'}{'curr_ind'};
   my $next_ind = $$self{'c'}{'next_ind'};
   my $prev_ind = $$self{'c'}{'prev_ind'};

   if ($$self{'c'}{'c_flow_type'} eq 'open') {
      push @script, qq(${curr_ind}echo "# $cmd";)
        if ($$self{'c'}{'g_type'} eq 'run'  &&  $$self{'c'}{'g_echo'} eq 'echo');
      push @script, qq(${curr_ind}$cmd);
      $self->_ind_plus();
      $curr_ind = $$self{'c'}{'curr_ind'};
      $next_ind = $$self{'c'}{'next_ind'};
      $prev_ind = $$self{'c'}{'prev_ind'};

   } elsif ($$self{'c'}{'c_flow_type'} eq 'cont') {
      push @script, qq(${prev_ind}$cmd);
      push @script, qq(${prev_ind}echo "# $cmd";)
        if ($$self{'c'}{'g_type'} eq 'run'  &&  $$self{'c'}{'g_echo'} eq 'echo');

   } else {
      $self->_ind_minus();
      $curr_ind = $$self{'c'}{'curr_ind'};
      $next_ind = $$self{'c'}{'next_ind'};
      $prev_ind = $$self{'c'}{'prev_ind'};
      push @script, qq(${curr_ind}$cmd);
      push @script, qq(${prev_ind}echo "# $cmd";)
        if ($$self{'c'}{'g_type'} eq 'run'  &&  $$self{'c'}{'g_echo'} eq 'echo');
   }

   return @script;
}

sub _cmd {
   my($self,$options,@cmd) = @_;
   my @script;
   $self->_cmd_options(%$options);

   push @script, $self->_cmd_init();
   push @script, $self->_cmd_exe(@cmd);
   push @script, $self->_cmd_term();

   return @script;
}

sub _cmd_init {
   my($self) = @_;
   my @script;
   return @script  if ($$self{'c'}{'c_meta'});
   my $curr_ind = $$self{'c'}{'curr_ind'};
   my $next_ind = $$self{'c'}{'next_ind'};
   my $prev_ind = $$self{'c'}{'prev_ind'};

   #
   # Print out a header to clarify the start of the command.
   #
   #   #
   #   # Command NUM
   #   #
   #

   push @script,
     '',
     qq(${curr_ind}#),
     qq(${curr_ind}# Command $$self{'c'}{'c_num'}),
     qq(${curr_ind}#),
     qq(${curr_ind}SC_CURR_EXIT=0;),
     qq(${curr_ind}SC_CURR_SUCC=0;);

   #
   # Handle command retries.  If a command is set to do retries,
   # we'll always do them, but if a command has failed with 'display'
   # mode, then we'll only do 1 iteration.
   #

   if ($$self{'c'}{'c_retries'} > 1) {
      push @script, qq(${curr_ind}SC_RETRIES=$$self{'c'}{'c_retries'};),
                    qq(${curr_ind}SC_TRY=0;),
                    qq(${curr_ind}while [ \$SC_TRY -lt \$SC_RETRIES ]; do);
      $self->_ind_plus();
      $curr_ind = $$self{'c'}{'curr_ind'};
      $next_ind = $$self{'c'}{'next_ind'};
      $prev_ind = $$self{'c'}{'prev_ind'};
   }

   return @script;
}

sub _cmd_term {
   my($self) = @_;
   my @script;
   return @script  if ($$self{'c'}{'c_meta'});
   my $curr_ind = $$self{'c'}{'curr_ind'};
   my $next_ind = $$self{'c'}{'next_ind'};
   my $prev_ind = $$self{'c'}{'prev_ind'};

   #
   # Handle command retries.
   #

   if ($$self{'c'}{'c_retries'} > 1) {
      push @script, qq(${curr_ind}if [ \$SC_CURR_EXIT -eq 0 ]; then),
                    qq(${next_ind}break;),
                    qq(${curr_ind}fi),
                    qq(${curr_ind}SC_TRY=`expr \$SC_TRY + 1`;);

      if ($$self{'c'}{'c_sleep'}) {
         push @script, qq(${curr_ind}if [ \$SC_TRY -lt \$SC_RETRIES ]; then),
                       qq(${next_ind}sleep $$self{'c'}{'c_sleep'};),
                       qq(${curr_ind}fi);
      }

      $self->_ind_minus();
      $curr_ind = $$self{'c'}{'curr_ind'};
      $next_ind = $$self{'c'}{'next_ind'};
      $prev_ind = $$self{'c'}{'prev_ind'};
      push @script, qq(${curr_ind}done);
   }

   #
   # Handle the current exit code
   #

   push @script,
     qq(${curr_ind}if [ \$SC_EXIT -eq 0  -a  \$SC_CURR_EXIT -ne 0 ]; then),
     qq(${next_ind}SC_EXIT=\$SC_CURR_EXIT;),
     qq(${next_ind}SC_FAILED=$$self{'c'}{'c_num'};),
     qq(${curr_ind}fi);

   #
   # If we have failed, then see what the options 'failure' is set to.
   #
   # If it is 'exit' or 'display', then we need to stop running
   # commands.  Since the script is wrapped as a subroutine, just
   # return.
   #

   if ($$self{'c'}{'g_fail'} eq 'exit'  ||  $$self{'c'}{'g_fail'} eq 'display') {
      push @script, qq(${curr_ind}if [ \$SC_EXIT -ne 0 ]; then),
                    qq(${next_ind}return),
                    qq(${curr_ind}fi);
   }

   return @script;
}

#####################
# Do a command (with any number of alternates)

sub _cmd_exe {
   my($self,@cmd) = @_;
   my @script;

   #
   # Handle each alternate of the command.  They will be numbered
   # starting at 1.
   #

   my $alt_num     = 0;
   while (@cmd) {
      $alt_num++;
      my $first    = ($alt_num==1 ? 1 : 0); # 1 if this is the first or only
                                            # alternate
      my $c        = shift(@cmd);
      my $last     = (! @cmd ? 1 : 0);      # 1 if this is the last alternate

      #
      # Add the command to the script
      #

      push @script, $self->_alt_init($c,$$self{'c'}{'c_num'},$alt_num);
      push @script, $self->_alt_cmd($c,$$self{'c'}{'c_num'},$alt_num,$first,$last);
      push @script, $self->_alt_term();
   }

   return @script;
}

#####################
# Set up a single command alternative.

sub _alt_init {
   my($self,$cmd,$cmd_num,$alt_num) = @_;
   my $curr_ind = $$self{'c'}{'curr_ind'};
   my $next_ind = $$self{'c'}{'next_ind'};
   my $prev_ind = $$self{'c'}{'prev_ind'};
   my @script;

   if (! $$self{'c'}{'c_meta'}) {
   #
   # Add some stuff to clarify the start of the command.
   #
   # If we're running it in 'script' mode, then we need to specify the
   # start of the output for this command.
   #
   # If we're just creating a script, we'll just add some comments.
   #

      if ($$self{'c'}{'g_type'} eq 'script') {
         push @script, qq(${curr_ind}echo "#SC CMD $cmd_num.$alt_num";)
           if ($$self{'c'}{'g_out'});
         push @script, qq(${curr_ind}echo "#SC CMD $cmd_num.$alt_num" >&2;)
           if ($$self{'c'}{'g_err'});

         if ($$self{'c'}{'c_retries'} > 1) {
            push @script, qq(${curr_ind}echo "#SC TRY \$SC_TRY";)
              if ($$self{'c'}{'g_out'});
            push @script, qq(${curr_ind}echo "#SC TRY \$SC_TRY" >&2;)
              if ($$self{'c'}{'g_err'});
         }

      } elsif ($$self{'c'}{'g_type'} eq 'run') {
         #
         # Command number comment
         #

         if ($$self{'c'}{'c_retries'} > 1) {
            push @script,
              qq(${curr_ind}#),
                qq(${curr_ind}# Command $cmd_num.$alt_num  [Retry: \$SC_TRY]),
                  qq(${curr_ind}#);
         } else {
            push @script,
              qq(${curr_ind}#),
                qq(${curr_ind}# Command $cmd_num.$alt_num),
                  qq(${curr_ind}#);
         }
      }
   }

   #
   # Display the command if running in 'run' mode with 'echo' selected.
   #

   if ($$self{'c'}{'g_type'} eq 'run'  &&  $$self{'c'}{'g_echo'} eq 'echo') {
      push @script, qq(${curr_ind}echo "# $cmd";);
   }

   return @script;
}

# This will finish up a command
#
sub _alt_term {
   my($self) = @_;
   my @script;
   return @script  if ($$self{'c'}{'c_meta'});
   my $curr_ind = $$self{'c'}{'curr_ind'};
   my $next_ind = $$self{'c'}{'next_ind'};
   my $prev_ind = $$self{'c'}{'prev_ind'};

   #
   # Make sure that the last command has included a newline when
   # running in script mode (for both STDOUT and STDERR).
   #

   if ($$self{'c'}{'g_type'} eq 'script') {
      push @script, qq(${curr_ind}echo "";)      if ($$self{'c'}{'g_out'});
      push @script, qq(${curr_ind}echo "" >&2;)  if ($$self{'c'}{'g_err'});
   }

   push @script, "";
   return @script;
}

sub _alt_cmd {
   my($self,$cmd,$cmd_num,$alt_num,$first,$last) = @_;
   my(@script);
   my $curr_ind = $$self{'c'}{'curr_ind'};
   my $next_ind = $$self{'c'}{'next_ind'};
   my $prev_ind = $$self{'c'}{'prev_ind'};

   # For the meta commnds (SC_* = VAL), we just run it (no special checks
   # needed).
   if ($$self{'c'}{'c_meta'}) {
      push @script, qq(${curr_ind}$cmd;);
      return @script;
   }

   my $redir = ($$self{'c'}{'c_noredir'} ? '' : $$self{'c'}{'g_redir'});

   # We want to generate essentially the following script:
   #
   #    CMD1
   #    if [ "$?" != 0 ]; then
   #       CMD2
   #    fi
   #    ...
   #    if [ "$?" != 0 ]; then
   #       CMDn
   #    fi
   #    if [ "$?" != 0 ]; then
   #       exit X
   #    fi
   #
   # where CMDn is the last alternate and X is the command number.
   #
   # If we have a 'check' option, we'll need to run that
   # command immediately after every CMDi.

   push @script,
     qq(${curr_ind}if [ \$SC_CURR_SUCC -eq 0 ]; then);

   $self->_ind_plus();
   $curr_ind = $$self{'c'}{'curr_ind'};
   $next_ind = $$self{'c'}{'next_ind'};
   $prev_ind = $$self{'c'}{'prev_ind'};

   push @script,
     qq(${curr_ind}$cmd $redir;);

   push @script,
     qq(${curr_ind}# CHECK WITH),
       qq(${curr_ind}$$self{'c'}{'c_check'} $redir;)  if ($$self{'c'}{'c_check'});

   # if command succeeded
   #   SC_CURR_SUCC = 1   -> this will mean that no more alternates run
   #   SC_CURR_EXIT = 0
   # else if this is the first alternate to fail
   #   SC_CURR_EXIT = $?  -> we'll use the first exit code if all alt. fail

   push @script, qq(${curr_ind}CMD_EXIT=\$?;),
                 qq(${curr_ind}if [ \$CMD_EXIT -eq 0 ]; then),
                 qq(${next_ind}SC_CURR_SUCC=1;),
                 qq(${next_ind}SC_CURR_EXIT=0;),
                 qq(${curr_ind}elif [ \$SC_CURR_EXIT -eq 0 ]; then),
                 qq(${next_ind}SC_CURR_EXIT=\$CMD_EXIT;),
                 qq(${curr_ind}fi);

   if ($$self{'c'}{'g_type'} eq 'script') {
      my $c = qq(echo "#SC EXIT $cmd_num.$alt_num \$CMD_EXIT");

      push @script, qq(${curr_ind}if [ \$CMD_EXIT -ne 0 ]; then);
      push @script, qq(${next_ind}${c};)      if ($$self{'c'}{'g_out'});
      push @script, qq(${next_ind}${c} >&2;)  if ($$self{'c'}{'g_err'});
      push @script, qq(${curr_ind}fi);
   }

   $self->_ind_minus();
   $curr_ind = $$self{'c'}{'curr_ind'};
   $next_ind = $$self{'c'}{'next_ind'};
   $prev_ind = $$self{'c'}{'prev_ind'};
   push @script,
     qq(${curr_ind}fi);

   return @script;
}

#####################
# This analyzes the options and sets some variables to determine
# how the script behaves.
#
# If we're creating a simple script, ignore retries.
#
sub _cmd_options {
   my($self,%options) = @_;

   $$self{'c'}{'c_meta'}    = ($options{'sc'}      ? $options{'sc'}      : 0);
   $$self{'c'}{'c_retries'} = ($options{'retry'}   ? $options{'retry'}   : 0) + 0;
   $$self{'c'}{'c_sleep'}   = ($options{'sleep'}   ? $options{'sleep'}   : 0) + 0;
   $$self{'c'}{'c_noredir'} = ($options{'noredir'} ? $options{'noredir'} : 0);
   $$self{'c'}{'c_check'}   = ($options{'check'}   ? $options{'check'}   : '');
}

#####################
# This analyzes the options and sets some variables to determine
# how the script behaves.
#
sub _script_options {
   my($self) = @_;

   #
   # What type of script, and whether it runs or not.
   #

   $$self{'c'}{'g_run'}  = $$self{'mode'};

   if ($$self{'c'}{'g_run'} eq 'dry-run') {
      $$self{'c'}{'g_type'} = $$self{'script'};
   } else {
      $$self{'c'}{'g_type'} = $$self{'c'}{'g_run'};
   }

   if ($$self{'c'}{'g_run'} eq 'run') {
      $$self{'c'}{'g_echo'} = $$self{'echo'};
   } else {
      $$self{'c'}{'g_echo'} = 0;
   }

   $$self{'c'}{'g_fail'} = $$self{'failure'};
   $$self{'c'}{'g_fail'} = ''  if ($$self{'c'}{'g_type'} eq 'simple');

   #
   # Analyze the 'output' and 'f-output' options.
   #
   #
   # If we ever want:
   #    STDOUT -> /dev/null,  STDERR -> STDOUT:
   # use:
   #    $$self{'c'}{'g_redir'} = '2>&1 >/dev/null';

   $$self{'c'}{'g_output'}  = $$self{'output'};
   $$self{'c'}{'g_foutput'} = $$self{'f-output'};

   if ($$self{'c'}{'g_type'} eq 'run') {

      if ($$self{'c'}{'g_output'} eq 'both') {
         # Capturing both so no redirection
         $$self{'c'}{'g_redir'} = '';
         $$self{'c'}{'g_out'}   = 1;
         $$self{'c'}{'g_err'}   = 1;

      } elsif ($$self{'c'}{'g_output'} eq 'merged') {
         # Merged output
         $$self{'c'}{'g_redir'} = '2>&1';
         $$self{'c'}{'g_out'}   = 1;
         $$self{'c'}{'g_err'}   = 0;

      } elsif ($$self{'c'}{'g_output'} eq 'stdout') {
         # Keep STDOUT, discard STDERR
         $$self{'c'}{'g_redir'} = '2>/dev/null';
         $$self{'c'}{'g_out'}   = 1;
         $$self{'c'}{'g_err'}   = 0;

      } elsif ($$self{'c'}{'g_output'} eq 'stderr') {
         # Discard STDOUT, keep STDERR
         $$self{'c'}{'g_redir'} = '>/dev/null';
         $$self{'c'}{'g_out'}   = 0;
         $$self{'c'}{'g_err'}   = 1;

      } elsif ($$self{'c'}{'g_output'} eq 'quiet') {
         # Discard everthing
         $$self{'c'}{'g_redir'} = '>/dev/null 2>&1';
         $$self{'c'}{'g_out'}   = 0;
         $$self{'c'}{'g_err'}   = 0;
      }

   } elsif ($$self{'c'}{'g_type'} eq 'script') {

      if ($$self{'c'}{'g_output'} eq 'merged'  ||
          ($$self{'c'}{'g_output'} eq 'quiet'  &&
           $$self{'c'}{'g_foutput'} eq 'merged')) {
         # Merged output
         $$self{'c'}{'g_redir'} = '2>&1';
         $$self{'c'}{'g_out'}   = 1;
         $$self{'c'}{'g_err'}   = 0;

         if ($$self{'c'}{'g_foutput'} eq 'both'    ||
             $$self{'c'}{'g_foutput'} eq 'stdout'  ||
             $$self{'c'}{'g_foutput'} eq 'stderr') {
            # If regular output is merged, then it cannot be
            # separate for a failed command.
            $$self{'f-output'} = 'merged';
         }

      } elsif ($$self{'c'}{'g_output'} eq 'quiet'  &&
               $$self{'c'}{'g_foutput'} eq 'quiet') {
         # Discard everthing
         $$self{'c'}{'g_redir'} = '>/dev/null 2>&1';
         $$self{'c'}{'g_out'}   = 0;
         $$self{'c'}{'g_err'}   = 0;

      } elsif (($$self{'c'}{'g_output'} eq 'stdout'   ||
                $$self{'c'}{'g_output'} eq 'quiet')  &&
               ($$self{'c'}{'g_foutput'} eq 'stdout'  ||
                $$self{'c'}{'g_foutput'} eq 'quiet')) {
         # We only need STDOUT
         $$self{'c'}{'g_redir'} = '2>/dev/null';
         $$self{'c'}{'g_out'}   = 1;
         $$self{'c'}{'g_err'}   = 0;

      } elsif (($$self{'c'}{'g_output'} eq 'stderr'   ||
                $$self{'c'}{'g_output'} eq 'quiet')  &&
               ($$self{'c'}{'g_foutput'} eq 'stderr'  ||
                $$self{'c'}{'g_foutput'} eq 'quiet')) {
         # We only need STDERR
         $$self{'c'}{'g_redir'} = '>/dev/null';
         $$self{'c'}{'g_out'}   = 0;
         $$self{'c'}{'g_err'}   = 1;

      } else {
         # Keep both.
         $$self{'c'}{'g_redir'} = '';
         $$self{'c'}{'g_out'}   = 1;
         $$self{'c'}{'g_err'}   = 1;

         if ($$self{'c'}{'g_foutput'} eq 'merged') {
            # We can't support merged output on a failed
            # command since it hasn't been merged, so we'll
            # just do the next best thing.
            $$self{'f-output'} = 'both';
         }
      }

   } else {   # $$self{'c'}{'g_type'} eq 'simple'

      $$self{'c'}{'g_redir'} = '';
      $$self{'c'}{'g_out'}   = 1;
      $$self{'c'}{'g_err'}   = 1;

   }
}

#####################
# The stdout/stderr from a script-mode run are each of the form:
#     #SC CMD N1.A1
#     ...
#     #SC CMD N2.A2
#     ...
# where N* are the command number and A* are the alternate number.
#
# Both may have:
#     #SC EXIT N1.A1 EXIT_VALUE
#
sub _script_output {
   my($self,$out,$err,$exit) = @_;
   $out    = ''  if (! defined $out);
   $err    = ''  if (! defined $err);
   my @out = split(/\n/,$out);
   my @err = split(/\n/,$err);

   #
   # Parse stdout and stderr and turn it into:
   #
   #   ( [ CMD_NUM_1, ALT_NUM_1, TRY_1, EXIT_1, STDOUT_1, STDERR_1 ],
   #     [ CMD_NUM_2, ALT_NUM_2, TRY_2, EXIT_2, STDOUT_2, STDERR_2 ], ... )
   #

   my @cmd;

   PARSE_LOOP:
   while (@out  ||  @err) {

      #
      # Get STDOUT/STDERR for the one command.
      #

      my($cmd_num,$alt_num,$cmd_exit,$cmd_try,$tmp);
      my($out_hdr,@stdout);
      my($err_hdr,@stderr);
      $cmd_exit = 0;
      $cmd_try  = 0;

      # STDOUT

      if (@out) {
         $out_hdr = shift(@out);

         # If there is any STDOUT, it MUST start with a header:
         #    #SC CMD X.Y
         #
         if ($out_hdr !~ /^\#SC CMD (\d+)\.(\d+)$/) {
            # Invalid output... should never happen
            $self->_print(1,"Missing command header in STDOUT: $out_hdr");
            return ();
         }

         ($cmd_num,$alt_num) = ($1,$2);

         while (@out  &&  $out[0] !~ /^\#SC CMD (\d+)\.(\d+)$/) {
            if      ($out[0] =~ /^\#SC_TRY (\d+)$/) {
               $cmd_try = $1;
               shift(@out);

            } elsif ($out[0] =~ /^\#SC EXIT $cmd_num\.$alt_num (\d+)$/) {
               $cmd_exit = $1;
               shift(@out);

            } else {
               push(@stdout,shift(@out));
            }
         }
      }

      # STDERR

      if (@err) {
         $err_hdr = shift(@err);

         # If there is any STDERR, it MUST start with a header:
         #    #SC CMD X.Y
         #
         if ($err_hdr !~ /^\#SC CMD (\d+)\.(\d+)$/) {
            # Invalid output... should never happen
            $self->_print(1,"Missing command header in STDERR: $err_hdr");
            return ();
         }

         ($cmd_num,$alt_num) = ($1,$2);

         # If there was any STDOUT, then the command headers must be
         # identical.
         #
         if ($out_hdr  &&  $err_hdr ne $out_hdr) {
            # Mismatched headers... should never happen
            $self->_print(1,"Mismatched header in STDERR: $err_hdr");
            return ();
         }

         while (@err  &&  $err[0] !~ /^\#SC CMD (\d+)\.(\d+)$/) {
            if      ($err[0] =~ /^\#SC_TRY (\d+)$/) {
               $tmp = $1;
               shift(@err);
               if ($out_hdr  &&  $tmp != $cmd_try) {
                  # Mismatched try number... should never happen
                  $self->_print(1,"Mismatched try number in STDERR: $err_hdr");
                  return ();
               }
               $cmd_try = $tmp;

            } elsif ($err[0] =~ /^\#SC EXIT $cmd_num\.$alt_num (\d+)$/) {
               $tmp = $1;
               shift(@err);
               if ($out_hdr  &&  $tmp != $cmd_exit) {
                  # Mismatched exit codes... should never happen
                  $self->_print(1,"Mismatched exit codes in STDERR: $err_hdr");
                  return ();
               }
               $cmd_exit = $tmp;

            } else {
               push(@stderr,shift(@err));
            }
         }
      }

      push (@cmd, [ $cmd_num,$alt_num,$cmd_try,$cmd_exit, \@stdout, \@stderr]);
   }

   #
   # Now go through this list and group all alternates together and determine
   # the status for each command.
   #
   # When looking at the I'th status list, we also have to take into account
   # the J'th (J=I+1) list:
   #
   #   I            J
   #   CMD ALT TRY  CMD ALT TRY
   #
   #   *   *   *    *   1   0/1     The current command determines status.
   #                                It will be '', succ, exit, fail, or disp.
   #
   #   C   A   T    C   A+1 T       The next command is another alternate.
   #                                Check it for status.
   #
   #   C   A   T    C   1   T+1     This command failed, but we will retry.
   #                                Status = 'retried'.
   #
   #   Everthing else is an error
   #

   my $failed = ($exit == 1 ? -1 : 0);
   my @ret    = ($failed);
   my @curr   = (0,undef);

   STATUS_LOOP:
   foreach (my $i = 0; $i < @cmd; $i++) {

      #
      # Get the values of current and next command, alt, and try
      # numbers.
      #

      my($curr_cmd_num,$curr_alt_num,$curr_try_num,
         $curr_exit,$curr_out,$curr_err) = @{ $cmd[$i] };

      my $next_cmd     = (defined $cmd[$i+1] ? 1 : 0);

      my($next_cmd_num,$next_alt_num,$next_try_num) =
        ($next_cmd ? @{ $cmd[$i+1] } : (0,1,0));

      #
      # Get the command that was actually run.
      #

      my $tmp  = $$self{'cmd'}[$curr_cmd_num-2][0];
      my @cmd  = (ref($tmp) ? @$tmp : ($tmp));
      my $c    = $cmd[$curr_alt_num-1];

      #
      # If this is the last alternate in a command that is not
      # being retried, we'll use this to determined the status.
      #
      # Status will be '', succ, or disp if it succeeds, or exit or
      # fail if it does not succeed.
      #

      if ($next_alt_num == 1  &&
          $next_try_num <= 1) {

         $curr[0] = $curr_cmd_num;
         push(@curr,[$c,$curr_exit,$curr_out,$curr_err]);

         if ($curr_exit) {
            if ($failed) {
               $curr[1] = 'fail';
            } else {
               $curr[1] = 'exit';
               $curr[0] = $i+1;
            }

         } else {
            if (! $failed) {
               $curr[1] = '';
            } elsif ($$self{'c'}{'g_fail'} eq 'display') {
               $curr[1] = 'disp';
            } else {
               $curr[1] = 'succ';
            }
         }

         push(@ret,[@curr]);
         @curr = (0,undef);

         next STATUS_LOOP;
      }

      #
      # If the next command is another alternate, we'll need to check
      # it for the status.
      #

      if ($next_cmd_num == $curr_cmd_num  &&
          $next_alt_num == ($curr_alt_num + 1)  &&
          $next_try_num == $curr_try_num) {

         push(@curr,[$c,$curr_exit,$curr_out,$curr_err]);
         next STATUS_LOOP;
      }

      #
      # If this command failed, but we will retry it, the status will
      # be 'retried'.
      #

      if ($next_cmd_num == $curr_cmd_num  &&
          $next_alt_num == 1  &&
          $next_try_num == ($curr_try_num+1)) {

         push(@curr,[$c,$curr_exit,$curr_out,$curr_err]);
         $curr[1] = 'retried';

         push(@ret,[@curr]);
         @curr = (0,undef);

         next STATUS_LOOP;
      }

      #
      # Everything else is an error in the output.
      #

      $self->_print(1,"Unexpected error in output: $i " .
                      "[$curr_cmd_num,$curr_alt_num,$curr_try_num] " .
                      "[$next_cmd_num,$next_alt_num,$next_try_num]");
      return ();
   }

   #
   # Do some final cleanup of the output including:
   #    discard STDOUT/STDERR based on output/f-output
   #    strip leading/trailing blank lines from STDOUT/STDERR if being kept
   #

   for (my $c = 1; $c <= $#ret; $c++) {
      my $status = $ret[$c][1];
      for (my $a = 2; $a <= $#{ $ret[$c] }; $a++) {
         my $out = $ret[$c][$a][2];
         my $err = $ret[$c][$a][3];

         # Keep STDOUT if:
         #    command succeded and output = both/merged/stdout
         #    command failed and f-output = both/merged/stdout
         #
         # Similar for STDERR.

         if ( (exists $succ_status{$status}  &&
               exists $keep_stdout{$$self{'c'}{'g_output'}})  ||
              (exists $fail_status{$status}  &&
               exists $keep_stdout{$$self{'c'}{'g_foutput'}}) ) {

            my @tmp = @$out;
            while (@tmp  &&  $tmp[0] eq '') {
               shift(@tmp);
            }
            while (@tmp  &&  $tmp[$#tmp] eq '') {
               pop(@tmp);
            }
            $out = [@tmp];

         } else {
            $out = [];
         }

         if ( (exists $succ_status{$status}  &&
               exists $keep_stderr{$$self{'c'}{'g_output'}})  ||
              (exists $fail_status{$status}  &&
               exists $keep_stderr{$$self{'c'}{'g_foutput'}}) ) {

            my @tmp = @$err;
            while (@tmp  &&  $tmp[0] eq '') {
               shift(@tmp);
            }
            while (@tmp  &&  $tmp[$#tmp] eq '') {
               pop(@tmp);
            }
            $err = [@tmp];

         } else {
            $err = [];
         }

         $ret[$c][$a][2] = $out;
         $ret[$c][$a][3] = $err;
      }
   }

   return @ret;
}

#####################
# Script indentation

sub _ind {
   my($self) = @_;
   $$self{'c'}{'curr_ind'} =
     " "x($$self{'c'}{'ind_per_lev'} * $$self{'c'}{'ind_cur_lev'});
   $$self{'c'}{'next_ind'} =
     " "x($$self{'c'}{'ind_per_lev'} * ($$self{'c'}{'ind_cur_lev'} + 1));
   $$self{'c'}{'prev_ind'} =
     " "x($$self{'c'}{'ind_cur_lev'} == 0
          ? 0
          : $$self{'c'}{'ind_per_lev'} * ($$self{'c'}{'ind_cur_lev'} - 1));
}

sub _ind_0 {
   my($self) = @_;
   $$self{'c'}{'ind_cur_lev'} = 0;
   $self->_ind();
}

sub _ind_plus {
   my($self) = @_;
   $$self{'c'}{'ind_cur_lev'}++;
   $self->_ind();
}
sub _ind_minus {
   my($self) = @_;
   $$self{'c'}{'ind_cur_lev'}--;
   $$self{'c'}{'ind_cur_lev'} = 0  if ($$self{'c'}{'ind_cur_lev'} < 0);
   $self->_ind();
}

###############################################################################

sub _print {
   my($self,$err,$text) = @_;

   # uncoverable branch false
   if ($ENV{'SHELL_CMD_TESTING'}) {
      return;
   }

   my $c = ($err ? "# ERROR: " : "# INFO: ");
   print {$err ? *STDERR : *STDOUT} "${c}${text}\n";

   return;
}

# This prepares a string to be enclosed in double quotes.
#
# Escape:  \ $ ` "
#
sub _quote {
   my($self,$string) = @_;

   $string =~ s/([\\\$`"])/\\$1/g;
   return $string;
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
