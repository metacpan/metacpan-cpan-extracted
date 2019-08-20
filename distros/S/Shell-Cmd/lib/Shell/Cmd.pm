package Shell::Cmd;
# Copyright (c) 2013-2018 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Variables used in scripts
#   SC_ORIG_DIRE     : the directory you were in when the script ran
#   SC_DIRE          : the working directory of the script
#   SC_DIRE_n        : the working directory going into command n
#   SC_FAILED = N    : the command which failed
#   SC_CURR_EXIT     : the exit code for the current command
#   SC_CURR_SUCC     : 1 if the current command (any alternate) succeeded
#   SC_RETRIES = N   : this command will run up to N times
#   SC_TRY = N       : we're currently on the Nth try

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
$VERSION = "3.03";

$| = 1;
$Data::Dumper::Sortkeys = 1;

###############################################################################
# METHODS TO CREATE OBJECT
###############################################################################

sub version {
   # uncoverable subroutine
   # uncoverable statement
   my($self) = @_;
   # uncoverable statement
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

   my $all                      = 1  if (! @opts);
   my %opts                     = map { $_,1 } @opts;

   # $self = {
   #           'g'       => { VAR => VAL }             global options
   #           'c'       => { VAR => VAL }             per-command options
   #           'e'       => [ VAR, VAL ]               environment
   #           'o'       => { out => STDOUT,           output from script mode
   #                          err => STDERR,
   #                          exit => EXIT }
   #           's'       => { HOST => { out => STDOUT, output from ssh script mode
   #                                    err => STDERR,
   #                                    exit => EXIT } }
   #           'curr'    => NUM,                       the current command in
   #                                                   the output method
   #           'err'     => ERROR,
   #           'cmd'     => { CMD_NUM => CMD_DESC }    command descriptions
   #           'cmd_num' => NUM
   #           'max_alt' => NUM                        the greatest number of
   #                                                   alternates
   #           'scr'     => []                         the current script

   $$self{'err'}                = '';
   $$self{'scr'}                = [];

   if ($all  ||  $opts{'opts'}) {
      $$self{'g'}               =
        {
         #
         # Options set with the options method.
         #

         'mode'            => 'run',
         'dire'            => '',
         'output'          => 'both',
         'script'          => '',
         'echo'            => 'noecho',
         'failure'         => 'exit',

         'tmp_script'      => "/tmp/.cmd.shell.$$",
         'tmp_script_keep' => 0,
         'ssh_script'      => '',
         'ssh_script_keep' => 0,

         'ssh_opts'        => {},
         'ssh_num'         => 1,
         'ssh_sleep'       => 0,

         #
         # A description of the script (calulated
         # from some of the obove options in _script_options).
         #
         # s_type    : Type of script currently being
         #             created.
         #               run, simple, script
         # simple    : Type of simple script currently being
         #             created.
         #               script  : s_type = script
         #               failure : s_type = run, failure = display
         # c_echo    : mode=run: echo,noecho,failed
         #             otherwise: ''
         # c_fail    : How to treat command failure
         #             in the calculated environment.
         #               simple: ''
         #               otherwise: exit,display,continue
         # out       : 1 if STDOUT captured
         # err       : 1 if STDERR captured
         # redir     : String to redirect output
         #

         's_type'          => '',
         'simple'          => '',
         'out'             => 0,
         'err'             => 0,
         'redir'           => '',
         'c_echo'          => '',
         'c_fail'          => '',

         #
         # Script indentation (used to keep track of
         # all indentation)
         #
         'ind_per_lev'     => 3,
         'ind_cur_lev'     => 0,
         'curr_ind'        => "",
         'next_ind'        => "",
         'prev_ind'        => "",

         #
         # Keep track of current flow structure
         # as commands are added (not used once
         # they are done).
         #
         #   ( [ FLOW, CMD_NUM ],
         #     [ FLOW, CMD_NUM ], ... )
         # where:
         #   FLOW     : type of flow
         #   CMD_NUM  : command where it opened
         #
         'flow'           => [],
        };
   }

   if ($all  ||  $opts{'commands'}) {
      # cmd => { CMD_NUM => { 'meta'      => VAL,   (0 or a string)
      #                       'label'     => LABEL,
      #                       'cmd'       => [ CMD ],
      #                       'dire'      => DIRE,
      #                       'noredir'   => 0/1,
      #                       'retry'     => NUM,
      #                       'sleep'     => NUM,
      #                       'check'     => CMD,
      #                       'flow'      => if/loop/...
      #                       'flow_type' => open/cont/close
      #                     }
      $$self{'cmd'}             = {};
      $$self{'cmd_num'}         = 1;
      $$self{'max_alt'}         = 0;
   }

   # Command options
   #   c_flow       1 if this is a flow command
   #   c_num        The number of the current command
   #   f_num        The failure code (c_num if <=200, 201 otherwise)
   #   alts         1 if alternates are available
   #   a_num        The number of the alternate
   #   c_label      The label for the command
   #
   #   c_retries    The number of retries
   #   c_sleep      How long to sleep between retries
   #   c_redir      Redirect string for this command (takes into account
   #                noredir)
   #   c_check      The command to check success
   #   c_check_q    The quoted check command
   #   simp         If the current command is in a simple script
   #
   #   cmd_str      The current command string
   #                e.g. '/bin/ls /tmp'
   #   cmd_str_q    The quoted command string
   #   cmd_label    A label describing the command (command number and
   #                command label if available):
   #                   '1'
   #                   '1 [LABEL]'
   #   alt_label    A label describing the alternate
   #                   '1.1'
   #                   '1.1 [LABEL]'
   #                   '1.0'             (if no alternates)

   $$self{'c'}                  = {};

   $$self{'e'}                  = []   if ($all  ||  $opts{'env'});

   if ($all  ||  $opts{'out'}) {
      $$self{'o'}               = {};
      $$self{'s'}               = {};
      $$self{'curr'}            = 0;
   }

   return;
}

###############################################################################
# METHODS TO SET OPTIONS
###############################################################################

sub dire {
   my($self,$dire) = @_;
   return $$self{'g'}{'dire'}  if (! defined($dire));

   return $self->options("dire",$dire);
}

sub mode {
   my($self,$mode) = @_;
   return $$self{'g'}{'mode'}  if (! defined($mode));

   return $self->options("mode",$mode);
}

sub env {
   my($self,@tmp) = @_;
   return @{ $$self{'e'} }  if (! @tmp);

   while (@tmp) {
      my $var = shift(@tmp);
      my $val = shift(@tmp);
      push @{ $$self{'e'} },($var,$val);
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
            $$self{'g'}{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt eq 'dire') {
         $$self{'g'}{$opt} = $self->_quote($val);
         next OPT;

      } elsif ($opt eq 'output') {

         if (lc($val) =~ /^(both|merged|stdout|stderr|quiet)$/) {
            $$self{'g'}{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt eq 'script') {

         if (lc($val) =~ /^(run|script|simple)$/) {
            $$self{'g'}{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt eq 'echo') {

         if (lc($val) =~ /^(echo|noecho|failed)$/) {
            $$self{'g'}{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt eq 'failure') {

         if (lc($val) =~ /^(exit|display|continue)$/) {
            $$self{'g'}{$opt} = lc($val);
            next OPT;
         }

      } elsif ($opt =~ s/^ssh://) {
         $$self{'g'}{'ssh_opts'}{$opt} = $val;
         next OPT;

      } elsif ($opt eq 'ssh_num'    ||
               $opt eq 'ssh_sleep'
              ) {
         $$self{'g'}{$opt} = $val;
         next OPT;

      } elsif ($opt eq 'tmp_script'       ||
               $opt eq 'tmp_script_keep'  ||
               $opt eq 'ssh_script'       ||
               $opt eq 'ssh_script_keep'
              ) {
         $$self{'g'}{$opt} = $val;
         next OPT;

      } else {
         $self->_err("Invalid option: $opt");
         return 1;
      }

      $self->_err("Invalid value: $opt [ $val ]");
      return 1;
   }

   return 0;
}

###############################################################################
# ADDING COMMANDS
###############################################################################

sub cmd {
   my($self,@args) = @_;

   while (@args) {
      my $cmd     = shift(@args);
      my $cmd_num = $$self{'cmd_num'}++;

      if (ref($cmd) ne ''  &&
          ref($cmd) ne 'ARRAY') {
         $$self{'err'} = "cmd must be a string or listref";
         $self->_err($$self{'err'});
         return 1;
      }

      my %options;
      if (@args  &&  ref($args[0]) eq 'HASH') {
         %options = %{ shift(@args) };
      }

      foreach my $opt (keys %options) {
         if ($opt !~ /^(dire|noredir|retry|sleep|check|label)$/) {
            $$self{'err'} = "Invalid cmd option: $opt";
            $self->_err($$self{'err'});
            return 1;
         }
         if ($opt eq 'dire') {
            $$self{'cmd'}{$cmd_num}{$opt} = $self->_quote($options{$opt});
         } else {
            $$self{'cmd'}{$cmd_num}{$opt} = $options{$opt};
         }
      }

      # Check if it is a flow command.  Also, make sure that flow
      # commands are properly opened, closed, and nested.

      my $err = $self->_cmd_flow($cmd,$cmd_num);
      return 1  if ($err);

      # If the command has alternates, update the max_alt value
      # as necessary.

      if (ref($cmd) eq 'ARRAY') {
         my $n = $#{ $cmd } + 1;
         if ($n > $$self{'max_alt'}) {
            $$self{'max_alt'} = $n;
         }

         $$self{'cmd'}{$cmd_num}{'cmd'} = $cmd;

      } else {
         $$self{'cmd'}{$cmd_num}{'cmd'} = [ $cmd ];
      }

   }
   return 0;
}

#####################
# Check whether a command is a flow command

sub _cmd_flow {
   my($self,$cmd,$cmd_num) = @_;

   # A flow command may not have alternatives, so it must be a single command.
   return  if (ref($cmd));

   my($flow,$type,$err);

   #
   # Check to see if it is a flow command
   #

   if ($cmd =~ /^\s*(if)\s+.*?;\s*then\s*$/   ||
       $cmd =~ /^\s*(elif)\s+.*?;\s*then\s*$/ ||
       $cmd =~ /^\s*(else)\s*$/               ||
       $cmd =~ /^\s*(fi)\s*$/) {
      $flow = $1;

      if ($flow eq 'if') {
         $err = $self->_cmd_open_flow($cmd_num,'if');
         $$self{'cmd'}{$cmd_num}{'flow_type'} = 'open';
      } elsif ($flow eq 'fi') {
         $err = $self->_cmd_close_flow($cmd_num,'if','fi');
         $$self{'cmd'}{$cmd_num}{'flow_type'} = 'close';
      } else {
         $err = $self->_cmd_cont_flow($cmd_num,'if',$flow);
         $$self{'cmd'}{$cmd_num}{'flow_type'} = 'cont';
      }
      $$self{'cmd'}{$cmd_num}{'flow'} = 'if';

   } elsif ($cmd =~ /^\s*(while)\s+.*?;\s*do\s*$/   ||
            $cmd =~ /^\s*(until)\s+.*?;\s*do\s*$/   ||
            $cmd =~ /^\s*(for)\s+.*?;\s*do\s*$/     ||
            $cmd =~ /^\s*(done)\s*$/) {
      $flow = $1;

      if ($flow eq 'while'  ||  $flow eq 'until'  ||  $flow eq 'for') {
         $err = $self->_cmd_open_flow($cmd_num,'loop [while|until|for]');
         $$self{'cmd'}{$cmd_num}{'flow_type'} = 'open';
      } else {
         $err = $self->_cmd_close_flow($cmd_num,'loop [while|until|for]','done');
         $$self{'cmd'}{$cmd_num}{'flow_type'} = 'close';
      }
      $$self{'cmd'}{$cmd_num}{'flow'} = 'loop';

   } else {
      return 0;
   }

   #
   # Flow commands may not have the following options:
   #    dire, noredir, retry, check
   #

   foreach my $opt ('dire','noredir','retry','check') {
      if (exists $$self{'cmd'}{$cmd_num}{$opt}) {
         $$self{'err'} = "$opt option not allowed with flow command: $cmd_num";
         return 1;
      }
   }

   return 1  if ($err);
   return 0;
}

sub _cmd_curr_flow {
   my($self) = @_;
   my @flow  = @{ $$self{'g'}{'flow'} };
   return ''  if (! @flow);
   return $flow[$#flow]->[0];
}
sub _cmd_open_flow {
   my($self,$cmd_num,$flow) = @_;

   push(@{ $$self{'g'}{'flow'} },
        [$flow,$cmd_num]);

   return 0;
}
sub _cmd_close_flow {
   my($self,$cmd_num,$flow,$close) = @_;

   my $curr_flow = $self->_cmd_curr_flow();
   if ($flow ne $curr_flow) {
      $$self{'err'} = "Broken flow: '$close' found, but no '$flow': $cmd_num";
      return 1;
   }

   pop(@{ $$self{'g'}{'flow'} });
   return 0;
}
sub _cmd_cont_flow {
   my($self,$cmd_num,$flow,$cont) = @_;

   my $curr_flow = $self->_cmd_curr_flow();
   if ($flow ne $curr_flow) {
      $$self{'err'} = "Broken flow: '$cont' found, but no '$flow': $cmd_num";
      return 1;
   }
   return 0;
}
sub _cmd_valid_script {
   my($self) = @_;

   return 1  if ($$self{'err'});
   my $curr_flow = $self->_cmd_curr_flow();
   if ($curr_flow) {
      $$self{'err'} = "Broken flow: '$curr_flow' opened, but not closed";
      return 1;
   }
   return 0;
}

###############################################################################
# RUN THE COMMANDS
###############################################################################

sub run {
   my($self)   = @_;
   if ($self->_cmd_valid_script()) {
      $self->_err($$self{'err'});
      return 252;
   }
   $self->_script();

   #
   # Return the script if this is a dry run.
   #

   my $script = join("\n",@{ $$self{'scr'} });
   return $script  if ($$self{'g'}{'mode'} eq 'dry-run');

   #
   # If it's running in real-time, do so.
   #

   my $tmp_script = $$self{'g'}{'tmp_script'};
   if (! $tmp_script) {
      $self->_err("tmp_script option must be set");
      return 254;
   }

   my $out = new IO::File;

   if ($out->open("> $tmp_script")) {
      print $out $script;
      $out->close();
   } else {
      $self->_err("tmp_script not writable");
      return 254;
   }

   my $err;
   if ($$self{'g'}{'mode'} eq 'run') {
      system(". $tmp_script");
      $err = $?;

      if (! $$self{'g'}{'tmp_script_keep'}) {
         unlink($tmp_script);
      }

      return $err;
   }

   #
   # If it's running in 'script' mode, capture the output so that
   # we can parse it.
   #

   my($stdout,$stderr,$exit);

   # We will always keep at least one of STDOUT/STDERR because they contain the
   # information necessary to see what commands run.  In 'quiet' mode, the
   # individual commands will discard all output, but the overall script will
   # still use STDOUT.
   if      ($$self{'g'}{'out'}  &&
            $$self{'g'}{'err'}) {
      ($stdout,$stderr,$exit) = capture         { system( ". $tmp_script" ) };
   } elsif ($$self{'g'}{'err'}) {
      ($stderr,$exit)          = capture_stderr { system( ". $tmp_script" ) };
   } else {
      ($stdout,$exit)          = capture_stdout { system( ". $tmp_script" ) };
   }
   $exit = $exit >> 8;

   if (! $$self{'g'}{'tmp_script_keep'}) {
      unlink($tmp_script);
   }

   $$self{'o'}{'out'}  = $self->_script_output($stdout)  if ($stdout);
   $$self{'o'}{'err'}  = $self->_script_output($stderr)  if ($stderr);
   $$self{'o'}{'exit'} = $exit;

   return $exit;
}

###############################################################################
# CREATE THE SCRIPT
###############################################################################

sub _script {
   my($self)  = @_;
   my(@ret);
   $self->_script_options();
   $self->_ind_0();

   while (1) {

      ##############################
      # If needed, we'll generate a simple script.
      #
      # The simple script is used in two ways:
      #   o  If a simple script is all that is needed, we'll use this
      #      to print out the list of commands that would run without
      #      all of the fancy error handling and I/O redirection.
      #   o  If the 'failure' option is set to 'display', we'll build
      #      in a function to the script that will display the commands
      #      that should have run.  This function will be called in
      #      the event of a failure.

      if ($$self{'g'}{'simple'}) {
         $self->_script_init('simple');

         foreach my $cmd_num (1 .. $$self{'cmd_num'}-1) {
            $self->_cmd_options($cmd_num,'simple');
            $self->_script_cmd($cmd_num)
         }

         $self->_script_term('simple');

         last  if ($$self{'g'}{'simple'} eq 'simple');
      }

      ##############################
      # Now generate the full script

      $self->_script_init();

      foreach my $cmd_num (1 .. $$self{'cmd_num'}-1) {
         $self->_cmd_options($cmd_num);
         $self->_script_cmd($cmd_num)
      }

      $self->_script_term();

      last;
   }
}

sub _script_init {
   my($self,$simple) = @_;
   my($text,$env,$text2);

   if ($simple) {
      $$self{'c'}{'simp'} = $$self{'g'}{'simple'};
   } else {
      $$self{'c'}{'simp'} = '';
   }

   if ($simple) {

      $text = <<'EOT';
<simp=failure>      : simple () {
<simp=failure>      :    echo ""
<simp=failure>      :    echo "#****************************************"
<simp=failure>      :    if   [ $SC_FAILED -eq 201 ]; then
<simp=failure>      :       echo "# The following script failed after command 200"
<simp=failure>      :    elif [ $SC_FAILED -gt 201 ]; then
<simp=failure>      :       echo "# The following script failed during initialization"
<simp=failure>      :    else
<simp=failure>      :       echo "# The following script failed at command $SC_FAILED"
<simp=failure>      :    fi
<simp=failure>      :    while read line ;do
<simp=failure>      :       echo "$line"
<simp=failure>      :    done << SC_SIMPLE_EOS
                    : SC_ORIG_DIRE=`pwd`;
EOT

   } else {
      $text = <<'EOT';
                    : SC_FAILED=0;
<c_echo=echo>       : echo "# SC_ORIG_DIRE=`pwd`";
                    : SC_ORIG_DIRE=`pwd`;
                    :
                    : main () {
EOT
   }

   $env = <<'EOT';
<c_echo=echo>       :    echo '# export <VAR>="<VAL>"';
                    :    export <VAR>="<VAL>";
EOT

   $text2 = <<'EOT';
<dire><c_echo=echo> :    echo '# SC_DIRE="<?dire?>"';
<dire>              :    SC_DIRE="<?dire?>";
<dire><c_echo=echo> :    echo '# cd "$SC_DIRE"';
<dire><simp>        :    cd "$SC_DIRE";
<dire><!simp>       :    cd "$SC_DIRE" 2>/dev/null;
<dire><!simp>       :    if [ $? -ne 0 ]; then
<dire><!simp>       :       SC_FAILED=255;
<dire><!simp>       :       return;
<dire><!simp>       :    fi
<!dire><c_echo=echo>:    echo "# SC_DIRE=$SC_ORIG_DIRE";
<!dire>             :    SC_DIRE=$SC_ORIG_DIRE;
EOT

   $self->_text_to_script($text);
   $self->_ind_plus()  if (! $simple);

   my(@tmp) = @{ $$self{'e'} };
   while (@tmp) {
      my $var  = shift(@tmp);
      my $val  = shift(@tmp);
      my $str  = $env;
      $str     =~ s/<VAR>/$var/g;
      $str     =~ s/<VAL>/$val/g;
      $self->_text_to_script($str);
   }

   $self->_text_to_script($text2);
}

sub _script_term {
   my($self,$simple) = @_;
   my($text);

   if ($simple) {
      $$self{'c'}{'simp'} = $$self{'g'}{'simple'};
      $text = <<'EOT';
                  : cd "$SC_ORIG_DIRE";
<simp=failure>    : SC_SIMPLE_EOS
<simp=failure>    : }
<simp=failure>    :
EOT

   } else {
      $self->_ind_minus();
      $text = <<'EOT';
                  : }
                  :
                  : main;
                  : cd "$SC_ORIG_DIRE";
<failure=display> : if [ $SC_FAILED -ne 0 ]; then
<failure=display> :    simple;
<failure=display> : fi
<c_echo=echo>     : echo '# cd "$SC_ORIG_DIRE"';
                  : exit $SC_FAILED;
                  :
EOT
   }

   $self->_text_to_script($text);
}

#####################
# This analyzes the options and sets some variables to determine
# how the script behaves.
#
sub _script_options {
   my($self) = @_;

   #
   # Calculate the type of script that we're creating.
   #
   # In dry-run mode, we may produce any of the script types:
   #    simple, run, script
   #
   # In run/script mode, we will produce that type of script.
   # We'll also produce a simple script for failure in 'run'
   # mode if 'failure' is 'display'.
   #

   if ($$self{'g'}{'mode'} eq 'dry-run') {
      $$self{'g'}{'s_type'} = ($$self{'g'}{'script'} ? $$self{'g'}{'script'} : 'run');
      if ($$self{'g'}{'script'} eq 'simple') {
         $$self{'g'}{'simple'} = 'simple';
      } elsif ($$self{'g'}{'s_type'} eq 'run'  &&
               $$self{'g'}{'failure'} eq 'display') {
         $$self{'g'}{'simple'} = 'failure';
      } else {
         $$self{'g'}{'simple'} = '';
      }
   } else {
      $$self{'g'}{'s_type'} = $$self{'g'}{'mode'};
      if ($$self{'g'}{'s_type'} eq 'run'  &&
          $$self{'g'}{'failure'} eq 'display') {
         $$self{'g'}{'simple'} = 'failure';
      } else {
         $$self{'g'}{'simple'} = '';
      }
   }

   #
   # Echoing commands applies to run mode.  In both dry-run and
   # script mode, it doesn't apply.
   #

   if ($$self{'g'}{'mode'} eq 'run') {
      $$self{'g'}{'c_echo'} = $$self{'g'}{'echo'};
   } else {
      $$self{'g'}{'c_echo'} = '';
   }

   #
   # When a command fails, we normally handle it using the 'failure'
   # option.  In a simple script, we don't do failure handling.
   #

   if ($$self{'g'}{'s_type'} eq 'simple') {
      $$self{'g'}{'c_fail'} = '';
   } else {
      $$self{'g'}{'c_fail'} = $$self{'g'}{'failure'};
   }

   #
   # Analyze the 'output' option to determine whether we are capturing
   # STDOUT and/or STDERR.  Set the 'redir' flag to the appropriate
   # string for performing this capture.
   #
   # 'simple' scripts do no redirection.
   #
   #
   # If we ever want:
   #    STDOUT -> /dev/null,  STDERR -> STDOUT:
   # use:
   #    $$self{'c'}{'g_redir'} = '2>&1 >/dev/null';

   if ($$self{'g'}{'s_type'} eq 'run'  ||
       $$self{'g'}{'s_type'} eq 'script') {

      if ($$self{'g'}{'output'} eq 'both') {
         # Capturing both so no redirection
         $$self{'g'}{'redir'} = '';
         $$self{'g'}{'out'}   = 1;
         $$self{'g'}{'err'}   = 1;
         $$self{'g'}{'quiet'} = 0;

      } elsif ($$self{'g'}{'output'} eq 'merged') {
         # Merged output
         $$self{'g'}{'redir'} = '2>&1';
         $$self{'g'}{'out'}   = 1;
         $$self{'g'}{'err'}   = 0;
         $$self{'g'}{'quiet'} = 0;

      } elsif ($$self{'g'}{'output'} eq 'stdout') {
         # Keep STDOUT, discard STDERR
         $$self{'g'}{'redir'} = '2>/dev/null';
         $$self{'g'}{'out'}   = 1;
         $$self{'g'}{'err'}   = 0;
         $$self{'g'}{'quiet'} = 0;

      } elsif ($$self{'g'}{'output'} eq 'stderr') {
         # Discard STDOUT, keep STDERR
         $$self{'g'}{'redir'} = '>/dev/null';
         $$self{'g'}{'out'}   = 0;
         $$self{'g'}{'err'}   = 1;
         $$self{'g'}{'quiet'} = 0;

      } else {
         # Discard everthing
         $$self{'g'}{'redir'} = '>/dev/null 2>&1';
         $$self{'g'}{'out'}   = 0;
         $$self{'g'}{'err'}   = 0;
         $$self{'g'}{'quiet'} = 1;
      }

   } else {
      # s_type = simple

      $$self{'g'}{'redir'} = '';
      $$self{'g'}{'out'}   = 1;
      $$self{'g'}{'err'}   = 1;

   }
}

###############################################################################
# ADD A COMMAND TO THE SCRIPT
###############################################################################

sub _script_cmd {
   my($self,$cmd_num) = @_;

   if ($$self{'cmd'}{$cmd_num}{'flow'}) {
      $self->_script_cmd_flow($cmd_num);
   } else {
      $self->_script_cmd_nonflow($cmd_num);
   }
}

sub _script_cmd_flow {
   my($self,$cmd_num) = @_;

   my $type = $$self{'cmd'}{$cmd_num}{'flow_type'};

   if ($type eq 'open') {
      $self->_script_cmd_cmd();
      $self->_ind_plus();
   } elsif ($type eq 'cont') {
      $self->_ind_minus();
      $self->_script_cmd_cmd();
      $self->_ind_plus();
   } else {
      $self->_ind_minus();
      $self->_script_cmd_cmd();
   }
}

sub _script_cmd_nonflow {
   my($self,$cmd_num) = @_;

   $self->_script_cmd_init($cmd_num);
   my $n = @{ $$self{'cmd'}{$cmd_num}{'cmd'} };

   if ($n > 1) {
      # Command with alternates

      for (my $a=1; $a<= $n; $a++) {
         $self->_alt_options($cmd_num,$a);
         $self->_script_cmd_cmd();
      }

   } else {
      # Single command

      $self->_script_cmd_cmd();
   }

   $self->_script_cmd_term($cmd_num);
}

sub _script_cmd_init {
   my($self,$cmd_num) = @_;

   my $text = <<'EOT';
<simp=failure>                : # <?cmd_label?>
<!simp>                       :
<!simp>                       : #
<!simp>                       : # Command <?cmd_label?>
<!simp>                       : #
<!simp>                       :
<!simp>                       : SC_CURR_EXIT=0;
<!simp>                       : SC_CURR_SUCC=0;
<dir>                         :
<dir><c_echo=echo>            : echo '# SC_DIRE_<?c_num?>=`pwd`';
<dir><c_echo=echo>            : echo '# cd "<?dir?>"';
<dir>                         : SC_DIRE_<?c_num?>=`pwd`;
<dir><simp>                   : cd "<?dir?>";
<dir><!simp>                  : cd "<?dir?>" 2>/dev/null;
<dir><!simp>                  : if [ $? -eq 0 ]; then
EOT

   $self->_text_to_script($text);

   $text = <<'EOT';
<!simp><c_retries>            :
<!simp><c_retries>            :    SC_RETRIES=<?c_retries?>;
<!simp><c_retries>            :    SC_TRY=0;
<!simp><c_retries>            :    while [ $SC_TRY -lt $SC_RETRIES ]; do
EOT

   $self->_text_to_script($text);
   $self->_ind_plus()  if ($$self{'c'}{'c_retries'}  &&  ! $$self{'c'}{'simp'});
}

sub _script_cmd_term {
   my($self,$cmd_num) = @_;

   my $text = <<'EOT';
<!simp><c_retries>            :
<!simp><c_retries>            :       if [ $SC_CURR_EXIT -eq 0 ]; then
<!simp><c_retries>            :          break;
<!simp><c_retries>            :       fi
<!simp><c_retries>            :       SC_TRY=`expr $SC_TRY + 1`;
<!simp><c_retries><c_sleep>   :       if [ $SC_TRY -lt $SC_RETRIES ]; then
<!simp><c_retries><c_sleep>   :          sleep <?c_sleep?>;
<!simp><c_retries><c_sleep>   :       fi
<!simp><c_retries>            :    done
EOT

   $self->_text_to_script($text);

   $text = <<'EOT';
<dir>                         :
<dir><!simp><c_echo=echo>     :    echo '# cd "$SC_DIRE_<?c_num?>"';
<dir>                         :    cd "$SC_DIRE_<?c_num?>";
<dir><!simp>                  : else
<dir><!simp>                  :    SC_CURR_EXIT=<?f_num?>;
<dir><!simp>                  : fi
EOT

   $self->_text_to_script($text);

   $text = <<'EOT';
<!simp>                       :
<!simp>                       : if [ $SC_FAILED -eq 0  -a  $SC_CURR_EXIT -ne 0 ]; then
<!simp>                       :    SC_FAILED=<?f_num?>;
<!simp>                       : fi
<!simp><!c_fail=continue>     :
<!simp><!c_fail=continue>     : if [ $SC_FAILED -ne 0 ]; then
<!simp><!c_fail=continue>     :    return;
<!simp><!c_fail=continue>     : fi
EOT

   $self->_text_to_script($text);
}

sub _script_cmd_cmd {
   my($self) = @_;
   my($text);

   # Print out any header and echo the command as appropriate

   if (! $$self{'c'}{'simp'}) {
      if (! $$self{'c'}{'c_flow'}) {
         $text = <<'EOT';
                                      :
                                      : #
                                      : # Command <?alt_label?>
                                      : #
<s_type=script>                       :
<s_type=script>                       : if [ $SC_CURR_SUCC -eq 0 ]; then
<s_type=script><out>                  :    echo "#SC CMD <?c_num?>.<?a_num?>";
<s_type=script><err>                  :    echo "#SC CMD <?c_num?>.<?a_num?>" >&2;
<s_type=script><quiet>                :    echo "#SC CMD <?c_num?>.<?a_num?>";
<s_type=script><c_retries><out>       :    echo "#SC TRY $SC_TRY";
<s_type=script><c_retries><err>       :    echo "#SC TRY $SC_TRY" >&2;
<s_type=script>                       : fi
<c_echo=echo>                         :
<c_echo=echo><alts><a_num=1>          : echo "# <?cmd_str_q?>";
<c_echo=echo><alts><a_num=1><c_check> : echo "#    Check with: <?c_check_q?>";
<c_echo=echo><alts><!a_num=1>         : echo "#    ALT: <?cmd_str_q?>";
<c_echo=echo><!alts>                  : echo "# <?cmd_str_q?>";
<c_echo=echo><!alts><c_check>         : echo "#    Check with: <?c_check_q?>";
EOT

         $self->_text_to_script($text);
      }
   }

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
   #
   # if command succeeded
   #   SC_CURR_SUCC = 1   -> this will mean that no more alternates run
   #   SC_CURR_EXIT = 0
   # else if this is the first alternate to fail
   #   SC_CURR_EXIT = $?  -> we'll use the first exit code if all alt. fail
   #
   # For script mode, make sure that both STDOUT and STDIN have a newline.


   if      ($$self{'c'}{'c_flow'}) {
      $text = <<'EOT';
                        :
                        :    <?cmd_str?>
EOT

   } elsif ($$self{'c'}{'simp'}) {
      $text = <<'EOT';
                        :    <?cmd_str?>;
EOT

   } else {
      $text = <<'EOT';
                        :
                        : if [ $SC_CURR_SUCC -eq 0 ]; then
                        :    <?cmd_str?><?c_redir?>;
<c_check>               :    # CHECK WITH
<c_check>               :    <?c_check?><?c_redir?>;
                        :    CMD_EXIT=$?;
<s_type=script><out>    :    echo "";
<s_type=script><err>    :    echo "" >&2;
                        :    if [ $CMD_EXIT -eq 0 ]; then
                        :       SC_CURR_SUCC=1;
                        :       SC_CURR_EXIT=0;
                        :    elif [ $SC_CURR_EXIT -eq 0 ]; then
                        :       SC_CURR_EXIT=$CMD_EXIT;
                        :    fi
<s_type=script>         :    if [ $CMD_EXIT -ne 0 ]; then
<s_type=script><out>    :       echo "#SC EXIT <?c_num?>.<?a_num?> $CMD_EXIT";
<s_type=script><err>    :       echo "#SC EXIT <?c_num?>.<?a_num?> $CMD_EXIT" >&2;
<s_type=script><quiet>  :       echo "#SC EXIT <?c_num?>.<?a_num?> $CMD_EXIT";
<s_type=script>         :    fi
                        : fi
EOT
   }

   $self->_text_to_script($text);
}

###################

# Set cmd_str and cmd_pref for the current command.
#
sub _alt_options {
   my($self,$cmd_num,$alt_num) = @_;
   my $label = $$self{'c'}{'c_label'};

   #
   # Only called with a command with alternates.
   #

   $$self{'c'}{'cmd_str'}   = $$self{'cmd'}{$cmd_num}{'cmd'}[$alt_num-1];
   $$self{'c'}{'cmd_str_q'} = $self->_quote($$self{'c'}{'cmd_str'});
   $$self{'c'}{'cmd_label'} = "$cmd_num" . ($label ? " [$label]" : '');
   $$self{'c'}{'alt_label'} = "$cmd_num.$alt_num";
   $$self{'c'}{'alts'}      = 1;
   $$self{'c'}{'a_num'}     = $alt_num;
}

sub _cmd_options {
   my($self,$cmd_num,$simple) = @_;

   $$self{'c'}{'c_num'}     = $cmd_num;
   $$self{'c'}{'f_num'}     = ($cmd_num > 200 ? 201 : $cmd_num);
   $$self{'c'}{'c_label'}   = $$self{'cmd'}{$cmd_num}{'label'};

   $$self{'c'}{'c_retries'} = ($$self{'cmd'}{$cmd_num}{'retry'}
                               ? $$self{'cmd'}{$cmd_num}{'retry'}+0
                               : 0);
   $$self{'c'}{'c_sleep'}   = ($$self{'cmd'}{$cmd_num}{'sleep'}
                               ? $$self{'cmd'}{$cmd_num}{'sleep'}+0
                               : 0);
   $$self{'c'}{'c_redir'}   = (($$self{'cmd'}{$cmd_num}{'noredir'} ||
                                $simple  ||
                                ! $$self{'g'}{'redir'})
                               ? ''
                               : ' ' . $$self{'g'}{'redir'} );
   $$self{'c'}{'c_check'}   = ($$self{'cmd'}{$cmd_num}{'check'}
                               ? $$self{'cmd'}{$cmd_num}{'check'}
                               : '');
   $$self{'c'}{'c_check_q'} = $self->_quote($$self{'c'}{'c_check'});
   $$self{'c'}{'c_dir'}     = ($$self{'cmd'}{$cmd_num}{'dire'}
                               ? $self->_quote($$self{'cmd'}{$cmd_num}{'dire'})
                               : '');

   $$self{'c'}{'c_retries'} = 0  if ($$self{'c'}{'c_retries'} == 1);

   $$self{'c'}{'ind'}       = $$self{'g'}{'curr_ind'};
   $$self{'c'}{'simp'}      = $$self{'g'}{'simple'}  if ($simple);

   $$self{'c'}{'c_flow'}    = ($$self{'cmd'}{$cmd_num}{'flow'} ? 1 : 0);

   # Handle the cases of a command with no alternates and init stuff

   my $n = @{ $$self{'cmd'}{$cmd_num}{'cmd'} };

   if ($n == 1) {
      #
      # A command with no alternates.
      #

      my $label = $$self{'c'}{'c_label'};
      $$self{'c'}{'cmd_str'}   = $$self{'cmd'}{$cmd_num}{'cmd'}[0];
      $$self{'c'}{'cmd_str_q'} = $self->_quote($$self{'c'}{'cmd_str'});
      $$self{'c'}{'cmd_label'} = $cmd_num . ($label ? " [$label]" : '');
      $$self{'c'}{'alt_label'} = "$cmd_num.0";
      $$self{'c'}{'alts'}      = 0;
      $$self{'c'}{'a_num'}     = 0;
   }
}

###############################################################################

# Text to script

sub _text_to_script {
   my($self,$text) = @_;
   my @script;

   # Text is a combination of:
   #    <TAG=VAL>  : CMD
   #    <!TAG=VAL> : CMD
   #    <TAG>      : CMD
   #    <!TAG>     : CMD
   #               : CMD
   #
   # <TAG=VAL>  means to include this line only if the given TAG has a value
   #            of 'VAL'.  The TAG can be either of:
   #               $$self{'c'}{TAG}
   #               $$self{'g'}{TAG}
   # <!TAG=VAL> means to include this line only if the given TAG does NOT
   #            have a value of 'VAL'
   # <TAG>      means to include this line only if the TAG has a true value
   # <!TAG>     means to include this line only if the TAG has a false value
   # CMD        can include indentation relative to the current text
   #            CMD can include <?TAG?> and it will be replaced by the
   #            value of TAG
   #
   # Every line must contain a colon, and the colon defines the start of
   # the actual line (so spacing to the right of the colon is used to
   # determine indentation).

   my @lines    = split(/\n/,$text);
   my $line_ind = '';

   LINE:
   foreach my $line (@lines) {
      $line =~ /(.*?)\s*:(\s*)(.*)$/;
      my($tags,$ind,$cmd) = ($1,$2,$3);

      while ($tags =~ s,^<(!?)(.*?)>,,) {
         my ($not,$tagstr) = ($1,$2);
         if ($tagstr =~ /^(.*?)=(.*)$/) {
            my($tag,$req) = ($1,$2);
            if ($self->_tagval($tag) eq $req) {
               next LINE  if ($not);
            } else {
               next LINE  if (! $not);
            }

         } else {
            my $tag = $tagstr;
            if ($self->_tagval($tag)) {
               next LINE  if ($not);
            } else {
               next LINE  if (! $not);
            }
         }
      }

      while ($cmd =~ /<\?(.*?)\?>/) {
         my $tag = $1;
         my $val = $self->_tagval($tag);
         $cmd    =~ s/<\?$tag\?>/$val/g;
      }

      if (! $cmd) {
         push(@script,'');
         next;
      }

      my $len             = length($ind);
      $line_ind           = $len  if ($line_ind eq '');

      if ($len > $line_ind) {
         $self->_ind_plus();
         $line_ind = $len;
      } elsif ($len < $line_ind) {
         $self->_ind_minus();
         $line_ind = $len;
      }
      my $spc = $$self{'g'}{'curr_ind'};
      push(@script,"${spc}$cmd");
   }

   push @{ $$self{'scr'} },@script;
}

sub _tagval {
   my($self,$tag) = @_;

   my $val;
   if (exists $$self{'c'}{$tag}) {
      $val = $$self{'c'}{$tag};
   } elsif (exists $$self{'g'}{$tag}) {
      $val = $$self{'g'}{$tag};
   }

   $val = ''  if (! defined($val));
   return $val;
}

#####################
# Script indentation

sub _ind {
   my($self) = @_;
   $$self{'g'}{'curr_ind'} =
     " "x($$self{'g'}{'ind_per_lev'} * $$self{'g'}{'ind_cur_lev'});
   $$self{'g'}{'next_ind'} =
     " "x($$self{'g'}{'ind_per_lev'} * ($$self{'g'}{'ind_cur_lev'} + 1));
   $$self{'g'}{'prev_ind'} =
     " "x($$self{'g'}{'ind_cur_lev'} == 0
          ? 0
          : $$self{'g'}{'ind_per_lev'} * ($$self{'g'}{'ind_cur_lev'} - 1));
}

sub _ind_0 {
   my($self) = @_;
   $$self{'g'}{'ind_cur_lev'} = 0;
   $self->_ind();
}

sub _ind_plus {
   my($self) = @_;
   $$self{'g'}{'ind_cur_lev'}++;
   $self->_ind();
}
sub _ind_minus {
   my($self) = @_;
   $$self{'g'}{'ind_cur_lev'}--;
   $self->_ind();
}

###############################################################################

sub _err {
   my($self,$text) = @_;

   # uncoverable branch false
   if ($ENV{'SHELL_CMD_TESTING'}) {
      return;
   }

   print STDERR "# ERROR: ${text}\n";
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

###############################################################################
# The stdout/stderr from a script-mode run are each of the form:
#     #SC CMD N1.A1
#     ...
#     #SC CMD N2.A2
#     ...
# where N* are the command number and A* are the alternate number.
#
# Retries are noted with:
#     #SC TRY T
#
# If the script fails, for the failing command, it includes:
#     #SC EXIT N1.A1 EXIT_VALUE
#
# STDOUT and STDERR are guaranteed to be identical in form (provided both
# are kept).
#
sub _script_output {
   my($self,$out) = @_;
   my @out = split(/\n/,$out);

   #
   # Parse stdout and turn it into:
   #
   #   ( [ CMD_NUM_1, ALT_NUM_1, TRY_1, EXIT_1, STDOUT_1 ],
   #     [ CMD_NUM_2, ALT_NUM_2, TRY_2, EXIT_2, STDOUT_2 ], ... )
   #

   my @cmd_raw;

   PARSE_LOOP:
   while (@out) {

      #
      # Get STDOUT (or STDERR) for the one command.
      #

      my($cmd_num,$alt_num,$cmd_exit,$cmd_try,$tmp);
      my($out_hdr,@output);
      $cmd_exit = 0;
      $cmd_try  = 0;

      $out_hdr = shift(@out);

      # The output MUST start with a header:
      #    #SC CMD X.Y
      #
      # uncoverable branch true
      if ($out_hdr !~ /^\#SC CMD (\d+)\.(\d+)$/) {
         # Invalid output... should never happen
         # uncoverable statement
         $self->_err("Missing command header in STDOUT: $out_hdr");
         # uncoverable statement
         return ();
      }

      ($cmd_num,$alt_num) = ($1,$2);

      while (@out  &&  $out[0] !~ /^\#SC CMD (\d+)\.(\d+)$/) {
         if      ($out[0] =~ /^\#SC TRY (\d+)$/) {
            $cmd_try = $1;
            shift(@out);

         } elsif ($out[0] =~ /^\#SC EXIT $cmd_num\.$alt_num (\d+)$/) {
            $cmd_exit = $1;
            shift(@out);

         } else {
            push(@output,shift(@out));
         }
      }

      pop(@output)  if (! defined($output[$#output])  ||  $output[$#output] eq '');
      push (@cmd_raw, [ $cmd_num,$alt_num,$cmd_try,$cmd_exit,\@output ]);
   }

   #
   # Now go through this list and group all alternates together and determine
   # the status for each command.
   #
   # This will now look like:
   #    ( CMD_1 CMD_2 ... )
   # where
   #    CMD_i = [ CMD_NUM EXIT TRY_1 TRY_2 ... ]
   #            CMD_NUM is the command number being executed
   #            EXIT    is the exit code produced by this command
   #            TRY_i   is the i'th retry (there will only be one if
   #                    the command does not have retries
   #
   # TRY_i = [ ALT_1 ALT_2 ... ]
   # ALT_i = [ LINE1 LINE2 ... ]    the output
   #
   # The exit code is the one produced by the very first alternate in the first
   # try.
   #
   # When looking at a command (I), we have to take into account the following
   # command (J = I+1).
   #
   #   I            J
   #   CMD ALT TRY  CMD ALT TRY
   #
   #   *   *   *    *   0/1 0       The next command is from a totally new
   #                                command, so the current command concludes
   #                                a retry and a command.
   #
   #   C   A   T    C   A+1 T       The next command is another alternate.
   #                                Add it to the current retry.
   #
   #   C   A   T    C   0/1 T+1     The next command starts another retry,
   #                                so the current command concludes a
   #                                retry, but NOT a command.
   #
   #   Everthing else is an error
   #

   my @cmds      = ();       # @cmds = ( CMD_1 CMD_2 ... )
   my @cmd       = ();       # @cmd  = ( TRY_1 TRY_2 ... )
   my @try       = ();       # @try  = ( ALT_1 ALT_2 ... )
   my $alt;                  # $alt  = [ LINE_1 LINE_2 ... ]
   my $cmd_curr  = 0;
   my $alt_curr  = 0;
   my $try_curr  = 0;
   my $cmd_next  = 0;
   my $alt_next  = 0;
   my $try_next  = 0;
   my $exit_curr = 0;
   my $exit_next = 0;
   my $i         = 0;

   ($cmd_curr,$alt_curr,$try_curr,$exit_curr,$alt) = @{ shift(@cmd_raw) };
   push(@try,$alt);

   COMMAND_LOOP:
   while (@cmd_raw) {
      $i++;

      ($cmd_next,$alt_next,$try_next,$exit_next,$alt) = @{ shift(@cmd_raw) };

      VALID_CONDITIONS: {

         ## ALT_NEXT = 0/1    and
         ## TRY_NEXT = 0
         ##    next command
         ##
         ## All valid CMD_NEXT != CMD_CURR entries will be covered here.

         if ($alt_next <= 1  &&
             $try_next == 0) {

            push(@cmd,[@try]);
            push(@cmds,[$cmd_curr,$exit_curr,@cmd]);
            @cmd      = ();
            @try      = ($alt);
            $cmd_curr = $cmd_next;
            $alt_curr = $alt_next;
            $try_curr = $try_next;
            $exit_curr= $exit_next;
            next COMMAND_LOOP;
         }

         # uncoverable branch true
         if ($cmd_next != $cmd_curr) {
            # uncoverable statement
            last VALID_CONDITIONS;
         }

         ## ALT_NEXT = ALT_CURR+1
         ##    next alternate
         ##
         ## All valid entries will have TRY_NEXT = TRY_CURR

         if ($alt_next == $alt_curr+1) {

            # uncoverable branch true
            if ($try_next != $try_curr) {
               # uncoverable statement
               last VALID_CONDITIONS;
            }

            push(@try,$alt);
            $alt_curr = $alt_next;
            $exit_curr= $exit_next;
            next COMMAND_LOOP;
         }

         ## ALT_NEXT = 0/1       and
         ## TRY_NEXT = TRY_CURR+1
         ##    next try
         ##
         ## Everything left must have both of these conditions.

         # uncoverable branch true
         if ($alt_next > 1) {
            # uncoverable statement
            last VALID_CONDITIONS;
         }

         # uncoverable branch true
         if ($try_next != $try_curr+1) {
            # uncoverable statement
            last VALID_CONDITIONS;
         }

         push(@cmd,[@try]);
         @try      = ($alt);
         $alt_curr = $alt_next;
         $try_curr = $try_next;
         $exit_curr= $exit_next;
         next COMMAND_LOOP;
      }

      #
      # Everything else is an error in the output (should never happen)
      #

      # uncoverable statement
      $self->_err("Unexpected error in output: $i " .
                  "[$cmd_curr,$alt_curr,$try_curr] " .
                  "[$cmd_next,$alt_next,$try_next]");
      # uncoverable statement
      return ();
   }

   #
   # Add on the last command is stored.
   #

   push(@cmd,[@try]);
   push(@cmds,[$cmd_curr,$exit_curr,@cmd]);

   return [@cmds];
}

###############################################################################

sub ssh {
   my($self,@hosts) = @_;

   if (! @hosts) {
      $self->_err("A host or hosts must be supplied with the ssh method");
      return;
   }

   if ($self->_cmd_valid_script()) {
      $self->_err("script flow commands not closed correctly");
      return;
   }
   $self->_script();

   #
   # Return the script if this is a dry run.
   #

   my $script = join("\n",@{ $$self{'scr'} });
   return $script  if ($$self{'g'}{'mode'} eq 'dry-run');

   #
   # Create the temporary script
   #

   my $tmp_script = $$self{'g'}{'tmp_script'};
   if (! $tmp_script) {
      $self->_err("tmp_script option must be set");
      return 254;
   }

   my $out = new IO::File;

   if ($out->open("> $tmp_script")) {
      print $out $script;
      $out->close();
   } else {
      $self->_err("tmp_script not writable");
      return 254;
   }

   #
   # Run the script
   #

   my %ret;
   if ($$self{'g'}{'ssh_num'} == 1) {
      %ret = $self->_ssh_serial(@hosts);
   } else {
      %ret = $self->_ssh_parallel(@hosts);
   }

   if (! $$self{'g'}{'tmp_script_keep'}) {
      unlink($tmp_script);
   }

   return %ret;
}

sub _ssh_serial {
   my($self,@hosts) = @_;
   my %ret;

   foreach my $host (@hosts) {
      $ret{$host} = $self->_ssh($host);
   }

   return %ret;
}

sub _ssh_parallel {
   my($self,@hosts) = @_;
   my %ret;

   my $max_proc = ($$self{'g'}{'ssh_num'} ? $$self{'g'}{'ssh_num'} : @hosts);
   my $manager = Parallel::ForkManager->new($max_proc);

   $manager->run_on_finish
     (
      sub {
         my($pid,$exit_code,$id,$signal,$core_dump,$data) = @_;
         my($host,$exit,$stdout,$stderr) = @$data;
         $ret{$host} = $exit;
         $$self{'s'}{$host}{'out'} = $self->_script_output($stdout)
           if (defined $stdout);
         $$self{'s'}{$host}{'err'} = $self->_script_output($stderr)
           if (defined $stderr);
         $$self{'s'}{$host}{'exit'} = $exit;
      }
     );

   foreach my $host (@hosts) {
      $manager->start and next;

      my @r = ($host,$self->_ssh($host));

      $manager->finish(0,\@r);
   }

   $manager->wait_all_children();
   return %ret;
}

sub _ssh {
   my($self,$host) = @_;

   my $ssh = Net::OpenSSH->new($host, %{ $$self{'g'}{'ssh_opts'} });

   my $script_loc = $$self{'g'}{'tmp_script'};
   my $script_rem = $$self{'g'}{'ssh_script'}  ||  $script_loc;
   $ssh->scp_put($script_loc,$script_rem)  or  return 253;

   #
   # If we're sleeping, do so.
   #

   if ($$self{'g'}{'ssh_sleep'}) {
      my $n = $$self{'g'}{'ssh_sleep'};
      if ($n < 0) {
         sleep(-$n);
      } else {
         sleep(int(rand($$self{'g'}{'ssh_sleep'})));
      }
   }

   #
   # If it's running in real-time, do so.
   #

   if ($$self{'g'}{'mode'} eq 'run') {
      $ssh->system({},". $script_rem");
      my $ret = $?;

      if (! $$self{'g'}{'ssh_script_keep'}) {
         $ssh->system({},"rm -f $script_rem");
      }
      return ($ret);
   }

   #
   # If it's running in script mode, do so.
   #

   my($stdout,$stderr,$exit);

   if      ($$self{'g'}{'err'}) {
      ($stdout,$stderr) = $ssh->capture2({},". $script_rem");
      $stdout           = undef  if (! $$self{'g'}{'out'});
   } elsif ($$self{'g'}{'out'}) {
      $stdout           = $ssh->capture({},". $script_rem");
   } else {
      $ssh->system({},". $script_rem");
   }
   $exit = $?;
   $exit = $exit >> 8;

   if (! $$self{'g'}{'ssh_script_keep'}) {
      $ssh->system({},"rm -f $script_rem");
   }

   return ($exit,$stdout,$stderr);
}

###############################################################################

sub output {
   my($self,%options) = @_;

   my $host = (exists $options{'host'}    ? $options{'host'}    : '');
   my $type = (exists $options{'output'}  ? $options{'output'}  : 'stdout');
   my $cmd  = (exists $options{'command'} ? $options{'command'} : 'curr');

   if ($type !~ /^(stdout|stderr|command|num|label|exit)$/) {
      $self->_err("Invalid output option: output=$type");
      return;
   }

   #
   # Output from ssh method
   #

   if ($host) {
      my @all = keys %{ $$self{'s'} };
      if (! @all) {
         $self->_err("Invalid option in output: " .
                     "host not allowed unless run with ssh method");
         return;
      }

      # host = all
      # host = HOST,HOST,...

      if ($host eq 'all'  ||  $host =~ /,/) {
         my %ret;
         my @host = ($host eq 'all'
                     ? @all
                     : split(/,/,$host));

         foreach my $host (@host) {
            if (! exists $$self{'s'}{$host}) {
               $self->_err("Host has no output: $host");
               next;
            }

            $ret{$host} = [ $self->_output($type,$cmd,$$self{'s'}{$host}) ];
         }
         return %ret;
      }

      # host = HOST

      if (! exists $$self{'s'}{$host}) {
         $self->_err("Host has no output: $host");
         return;
      }
      return $self->_output($type,$cmd,$$self{'s'}{$host});
   }

   #
   # Output from run method
   #

   return $self->_output($type,$cmd,$$self{'o'});
}

sub _output {
   my($self,$type,$cmd,$output) = @_;

   #
   # Figure out which output sections need to be returned.
   #

   my @c;
   my $no  = (exists $$output{'out'} ? @{ $$output{'out'} } : 0);
   my $ne  = (exists $$output{'err'} ? @{ $$output{'err'} } : 0);
   my $max = ($no > $ne ? $no : $ne);

   if ($cmd eq 'curr') {
      push @c,$$self{'curr'};

   } elsif ($cmd eq 'next') {
      $$self{'curr'}++;
      push @c,$$self{'curr'};

   } elsif ($cmd eq 'all') {
      push @c, (0 .. ($max-1));

   } elsif ($cmd eq 'fail') {
      # Find the command that failed.

      foreach my $i (0 .. ($max-1)) {
         if (exists $$output{'out'}  &&  defined $$output{'out'}[$i]) {
            if ($$output{'out'}[$i][1]) {
               push(@c,$i);
               last;
            }

         } elsif (exists $$output{'err'}  &&  defined $$output{'err'}[$i]) {
            if ($$output{'err'}[$i][1]) {
               push(@c,$i);
               last;
            }
         }
      }

   } elsif ($cmd =~ /^\d+$/) {
      # CMD_NUM

      foreach my $i (0 .. ($max-1)) {
         if (exists $$output{'out'}  &&  defined $$output{'out'}[$i]) {
            if ($$output{'out'}[$i][0] eq $cmd) {
               push(@c,$i);
            }

         } elsif (exists $$output{'err'}  &&  defined $$output{'err'}[$i]) {
            if ($$output{'err'}[$i][0] eq $cmd) {
               push(@c,$i);
            }
         }
      }

   } else {
      # LABEL

      foreach my $i (0 .. ($max-1)) {
         if (exists $$output{'out'}  &&  defined $$output{'out'}[$i]) {
            my $n = $$output{'out'}[$i][0];
            if ($$self{'cmd'}{$n}{'label'} eq $cmd) {
               push(@c,$i);
            }

         } elsif (exists $$output{'err'}  &&  defined $$output{'err'}[$i]) {
            my $n = $$output{'err'}[$i][0];
            if ($$self{'cmd'}{$n}{'label'} eq $cmd) {
               push(@c,$i);
            }
         }
      }
   }

   return  if (! @c);

   #
   # Now gather up the stuff to return.
   #

   my @ret;

   foreach my $i (@c) {
      if      ($type eq 'stdout') {
         my @r;
         if (exists $$output{'out'}  &&  defined $$output{'out'}[$i]) {
            my @tmp = @{ $$output{'out'}[$i] };
            shift(@tmp);
            shift(@tmp);
            foreach my $try (@tmp) {
               foreach my $alt (@$try) {
                  push(@r,@$alt);
               }
            }
            push(@ret,[@r]);
         }

      } elsif ($type eq 'stderr') {
         my @r;
         if (exists $$output{'err'}  &&  defined $$output{'err'}[$i]) {
            my @tmp = @{ $$output{'err'}[$i] };
            shift(@tmp);
            shift(@tmp);
            foreach my $try (@tmp) {
               foreach my $alt (@$try) {
                  push(@r,@$alt);
               }
            }
            push(@ret,[@r]);
         }

      } elsif ($type eq 'command') {
         my $n;
         if (exists $$output{'out'}  &&  defined $$output{'out'}[$i]) {
            $n = $$output{'out'}[$i][0];
         } elsif (exists $$output{'err'}  &&  defined $$output{'err'}[$i]) {
            $n = $$output{'err'}[$i][0];
         }
         push(@ret,$$self{'cmd'}{$n}{'cmd'});

      } elsif ($type eq 'num') {
         my $n;
         if (exists $$output{'out'}  &&  defined $$output{'out'}[$i]) {
            $n = $$output{'out'}[$i][0];
         } elsif (exists $$output{'err'}  &&  defined $$output{'err'}[$i]) {
            $n = $$output{'err'}[$i][0];
         }
         push(@ret,$n);

      } elsif ($type eq 'label') {
         my $n;
         if (exists $$output{'out'}  &&  defined $$output{'out'}[$i]) {
            $n = $$output{'out'}[$i][0];
         } elsif (exists $$output{'err'}  &&  defined $$output{'err'}[$i]) {
            $n = $$output{'err'}[$i][0];
         }
         push(@ret,$$self{'cmd'}{$n}{'label'});

      } elsif ($type eq 'exit') {
         my $exit;
         if (exists $$output{'out'}  &&  defined $$output{'out'}[$i]) {
            $exit = $$output{'out'}[$i][1];
         } elsif (exists $$output{'err'}  &&  defined $$output{'err'}[$i]) {
            $exit = $$output{'err'}[$i][1];
         }
         push(@ret,$exit);
      }
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
