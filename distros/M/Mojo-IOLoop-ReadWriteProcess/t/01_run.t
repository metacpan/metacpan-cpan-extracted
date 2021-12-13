#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use Test::Exception;
use POSIX;
use FindBin;
use IO::Select;
use Mojo::File qw(tempfile path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");
use Mojo::IOLoop::ReadWriteProcess qw(process);
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt);

subtest process => sub {

  my $c = Mojo::IOLoop::ReadWriteProcess->new();

  can_ok($c, qw(verbose _diag));

  my $buffer;
  {
    open my $handle, '>', \$buffer;
    local *STDERR = $handle;
    $c->_diag("FOOTEST");
  };
  like $buffer, qr/>> main::__ANON__(.*\])*\(\): FOOTEST/,
    "diag() correct output format";
};

subtest 'process basic functions' => sub {

  my $p = Mojo::IOLoop::ReadWriteProcess->new();
  eval {
    $p->start();
    $p->stop();
  };
  ok $@,   "Error expected";
  like $@, qr/Nothing to do/,
    "Process with no code nor execute command, will fail";

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01
  );
  eval { $p->_fork(); };
  ok $@, "Error expected";
  like $@, qr/Can't spawn child without code/, "_fork() with no code will fail";

  my @output;
  {
    pipe(PARENT, CHILD);

    my $p = Mojo::IOLoop::ReadWriteProcess->new(
      kill_sleeptime        => 0.01,
      sleeptime_during_kill => 0.01,
      code                  => sub {
        close(PARENT);
        open STDERR, ">&", \*CHILD or die $!;
        print STDERR "FOOBARFTW\n" while 1;
      })->start();
    close(CHILD);
    @output = scalar <PARENT>;
    $p->stop();
    chomp @output;
  }
  is $output[0], "FOOBARFTW", 'right output';
};

subtest 'process is_running()' => sub {

  my @output;
  pipe(PARENT, CHILD);

  my $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    code                  => sub {
      close(PARENT);
      open STDERR, ">&", \*CHILD or die $!;
      print STDERR "FOOBARFTW\n";
    });

  $p->start();
  close(CHILD);
  @output = scalar <PARENT>;
  $p->stop();

  close(PARENT);
  chomp @output;
  is $output[0], "FOOBARFTW", 'right output from process';
  is $p->is_running, 0, "Process now is stopped";

  # Redefine new code and restart it.
  pipe(PARENT, CHILD);
  $p->code(
    sub {
      close(PARENT);
      open STDERR, ">&", \*CHILD or die $!;
      print STDERR "FOOBAZFTW\n";
      1 while 1;
    });
  $p->restart()->restart()->restart();
  is $p->is_running, 1, "Process now is running";
  close(CHILD);
  @output = scalar <PARENT>;
  $p->stop();
  chomp @output;
  is $output[0], "FOOBAZFTW", 'right output from process';
  is $p->is_running, 0, "Process now is not running";
  @output = ('');

  pipe(PARENT, CHILD);
  $p->restart();

# Give time to the child to be up
  my $attempts = 100;
  until ($p->is_running || $attempts == 0) {
    sleep .1;
    $attempts--;
  }

  is $p->is_running, 1, "Process now is running";
  close(CHILD);
  @output = scalar <PARENT>;
  $p->stop();
  chomp @output;
  is $output[0], "FOOBAZFTW", 'right output from process';
};

subtest 'process execute()' => sub {
  my $test_script         = "$FindBin::Bin/data/process_check.sh";
  my $test_script_sigtrap = "$FindBin::Bin/data/term_trap.sh";
  plan skip_all =>
    "You do not seem to have bash, which is required (as for now) for this test"
    unless -e '/bin/bash';
  plan skip_all =>
"You do not seem to have $test_script. The script is required to run the test"
    unless -e $test_script;
  plan skip_all =>
"You do not seem to have $test_script_sigtrap. The script is required to run the test"
    unless -e $test_script_sigtrap;
  my $p = Mojo::IOLoop::ReadWriteProcess->new(
    sleeptime_during_kill => 0.1,
    execute               => $test_script
  )->start();
  is $p->getline,     "TEST normal print\n", 'Get right output from stdout';
  is $p->err_getline, "TEST error print\n",  'Get right output from stderr';
  is $p->is_running, 1, 'process is still waiting for our input';
  $p->write("FOOBAR");
  is $p->read, "you entered FOOBAR\n",
    'process received input and printed it back';
  $p->stop();
  is $p->is_running, 0, 'process is not running anymore';

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    execute               => $test_script,
    args                  => [
      qw(FOO
        BAZ)
    ])->start();
  is $p->stdout,      "TEST normal print\n", 'Get right output from stdout';
  is $p->err_getline, "TEST error print\n",  'Get right output from stderr';
  is $p->is_running, 1, 'process is still waiting for our input';
  $p->write("FOOBAR");
  is $p->getline, "you entered FOOBAR\n",
    'process received input and printed it back';
  $p->wait_stop();
  is $p->is_running,  0,           'process is not running anymore';
  is $p->getline,     "FOO BAZ\n", 'process received extra arguments';
  is $p->exit_status, 100,         'able to retrieve function return';

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    sleeptime_during_kill => 0.1,
    execute               => $test_script
  )->args([qw(FOO BAZ)])->start();
  is $p->stdout,      "TEST normal print\n", 'Get right output from stdout';
  is $p->err_getline, "TEST error print\n",  'Get right output from stderr';
  is $p->is_running, 1, 'process is still waiting for our input';
  $p->write("FOOBAR");
  is $p->getline, "you entered FOOBAR\n",
    'process received input and printed it back';
  $p->wait_stop();
  is $p->is_running,  0,           'process is not running anymore';
  is $p->getline,     "FOO BAZ\n", 'process received extra arguments';
  is $p->exit_status, 100,         'able to retrieve function return';

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    separate_err          => 0,
    execute               => $test_script
  );
  $p->start();
  is $p->is_running, 1, 'process is still running';
  is $p->getline, "TEST error print\n",
    'Get STDERR output from stdout, always in getline()';
  $p->stop();
  like $p->getline, qr/TEST (exiting|normal print)/,
    'Still able to get stdout output, always in getline()';

  my $p2 = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    separate_err          => 0,
    execute               => $test_script,
    set_pipes             => 0
  );
  $p2->start();
  is $p2->getline, undef, "pipes are correctly disabled";
  $p2->stop();
  is !!$p2->_status, 1,
    'take exit status even with set_pipes = 0 (we killed it)';

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    verbose               => 1,
    separate_err          => 0,
    execute               => $test_script_sigtrap,
    max_kill_attempts     => -4,
  );    # ;)
  $p->start();
  $p->stop();
  is $p->is_running, 1, 'process is still running';
  is $p->_status, undef, 'no status yet';
  my $err = ${(@{$p->error})[0]};
  my $exp = qr/Could not kill process/;
  like $err, $exp, 'Error is not empty if process could not be killed';
  $p->max_kill_attempts(50);
  $p->blocking_stop(0);
  $p->stop();
  is $p->is_running, 1, 'process is still running';
  $p->blocking_stop(1);
  $p->max_kill_attempts(5);
  $p->stop;
  $p->wait;
  is $p->is_running, 0, 'process is shut down';
  is $p->errored,    1, 'Process died and errored';


  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    verbose               => 1,
    separate_err          => 0,
    blocking_stop         => 1,
    execute               => $test_script,
    max_kill_attempts     => -1              # ;)
  )->start()->stop();

  is $p->is_running, 0,
    'process is shut down by kill signal when "blocking_stop => 1"';

  my $pidfile = tempfile;
  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    verbose               => 1,
    separate_err          => 0,
    blocking_stop         => 1,
    execute               => $test_script,
    max_kill_attempts     => -1,             # ;)
    pidfile               => $pidfile
  )->start();
  my $pid = path($pidfile)->slurp();
  is -e $pidfile, 1, 'Pidfile is there!';
  is $pid, $p->pid, "Pidfile was correctly written";
  $p->stop();
  is -e $pidfile, undef, 'Pidfile got removed after stop()';

  $pidfile = tempfile;
  $p       = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    verbose               => 1,
    separate_err          => 0,
    blocking_stop         => 1,
    execute               => $test_script,
    max_kill_attempts     => -1,             # ;)
  )->start();
  $p->write_pidfile($pidfile);
  $pid = path($pidfile)->slurp();
  is -e $pidfile, 1, 'Pidfile is there!';
  is $pid, $p->pid, "Pidfile was correctly written";
  $p->stop();
  is -e $pidfile, undef, 'Pidfile got removed after stop()';

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    verbose               => 1,
    separate_err          => 0,
    blocking_stop         => 1,
    execute               => $test_script,
    max_kill_attempts     => -1,             # ;)
  )->start();
  is $p->write_pidfile(), undef, "No filename given to write_pidfile";
  $p->stop();
};

subtest 'process(execute =>"/usr/bin/true")' => sub {
  plan skip_all => "Missing '/usr/bin/true'" unless -e '/usr/bin/true';

  is(process(execute => '/usr/bin/true')->quirkiness(1)->start()->wait_stop()->exit_status(), 0, 'Simple exec of "/usr/bin/true" return 0');
};

subtest 'process code()' => sub {
  my $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    code                  => sub {
      my ($self)        = shift;
      my $parent_output = $self->channel_out;
      my $parent_input  = $self->channel_in;

      print $parent_output "FOOBARftw\n";
      print "TEST normal print\n";
      print STDERR "TEST error print\n";
      print "Enter something : ";
      my $a = <STDIN>;
      chomp($a);
      print "you entered $a\n";
      my $parent_stdin = $parent_input->getline;
      print $parent_output "PONG\n" if $parent_stdin eq "PING\n";
      exit 0;
    })->start();
  $p->channel_in->write("PING\n");
  is $p->getline,    "TEST normal print\n", 'Get right output from stdout';
  is $p->stderr,     "TEST error print\n",  'Get right output from stderr';
  is $p->is_running, 1,                     'process is running';
  $p->write("FOOBAR\n");
  is(IO::Select->new($p->read_stream)->can_read(10),
    1, 'can read from stdout handle');
  is $p->getline, "Enter something : you entered FOOBAR\n", 'can read output';
  is $p->channel_out->getline, "FOOBARftw\n", "can read from internal channel";
  is $p->channel_read_handle->getline, "PONG\n",
    "can read from internal channel";
  $p->stop();
  is $p->is_running, 0, 'process is not running';
  $p->restart();

  $p->channel_write("PING");
  is $p->getline,    "TEST normal print\n", 'Get right output from stdout';
  is $p->stderr,     "TEST error print\n",  'Get right output from stderr';
  is $p->is_running, 1,                     'process is running';
  is $p->channel_read(), "FOOBARftw\n",
    "Read from channel while process is running";
  $p->write("FOOBAR");
  is(IO::Select->new($p->read_stream)->can_read(10),
    1, 'can read from stdout handle');

  is $p->read_all, "Enter something : you entered FOOBAR\n",
    'Get right output from stdout';
  $p->stop();

  my @result = $p->read_all;
  is @result, 0, 'output buffer is now empty';

  is $p->channel_read_handle->getline, "PONG\n",
    "can read from internal channel";
  is $p->is_running, 0, 'process is not running';

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    separate_err          => 0,
    code                  => sub {
      my ($self)        = shift;
      my $parent_output = $self->channel_out;
      my $parent_input  = $self->channel_in;

      print "TEST normal print\n";
      print STDERR "TEST error print\n";
      return "256";
    })->start();
  is $p->getline, "TEST normal print\n", 'Get right output from stderr/stdout';
  is $p->getline, "TEST error print\n",  'Get right output from stderr/stdout';
  $p->wait_stop();
  is $p->is_running,    0,   'process is not running';
  is $p->return_status, 256, 'right return code';

  $p = Mojo::IOLoop::ReadWriteProcess->new(sub { die "Fatal error"; },
    sleeptime_during_kill => 0.1);
  my $event_fired = 0;
  $p->on(
    process_error => sub {
      $event_fired = 1;
      like(pop->first->to_string, qr/Fatal error/, 'right error from event');
    });
  $p->start();
  $p->wait_stop();
  is $p->is_running,    0,     'process is not running';
  is $p->return_status, undef, 'process did not return nothing';
  is $p->errored,       1,     'Process died';

  like(${(@{$p->error})[0]}, qr/Fatal error/, 'right error');
  is $event_fired, 1, 'error event fired';

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    sub { return 42 },
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    internal_pipes        => 0
  );
  $p->start();
  $p->wait_stop();
  is $p->is_running, 0, 'process is not running';
  is $p->return_status, undef,
    'process did not return nothing when internal_pipes are disabled';

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    sub { die "Bah" },
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    internal_pipes        => 0
  );
  $p->start();
  $p->wait_stop();
  is $p->is_running, 0, 'process is not running';
  is $p->errored,    0, 'process did not errored, we dont catch errors anymore';

# XXX: flaky test temporarly skip it. is !!$p->exit_status, 1, 'Exit status is there';

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    separate_err          => 0,
    set_pipes             => 0,
    code                  => sub {
      print "TEST normal print\n";
      print STDERR "TEST error print\n";
      return "256";
    })->start();
  is $p->getline, undef, 'no output from pipes expected';
  is $p->getline, undef, 'no output from pipes expected';
  $p->wait_stop();
  is $p->return_status, 256, "grab exit_status even if no pipes are set";

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    separate_err          => 0,
    set_pipes             => 1,
    code                  => sub {
      exit 100;
    })->start();
  $p->wait_stop();
  is $p->exit_status, 100, "grab exit_status even if no pipes are set";

  $p = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime        => 0.01,
    sleeptime_during_kill => 0.01,
    separate_err          => 0,
    code                  => sub {
      print STDERR "TEST error print\n" for (1 .. 6);
      my $a = <STDIN>;
    })->start();
  like $p->stderr_all, qr/TEST error print/,
'read all from stderr, is like reading all from stdout when separate_err = 0';
  $p->stop()->separate_err(1)->start();
  $p->write("a");
  $p->wait_stop();
  like $p->stderr_all, qr/TEST error print/, 'read all from stderr works';
  is $p->read_all,     '',                   'stdout is empty';
};

subtest stop_whole_process_group_gracefully => sub {
  my $test_script = "$FindBin::Bin/data/simple_fork.pl";
  plan skip_all =>
    "You do not seem to have $test_script which is required to run the test"
    unless -e $test_script;

  # run the "term_trap.pl" script and its sub processes within its own
  # process group
  # notes: - Not using "term_trap.sh" here because bash interferes with the
  #          process group.
  #        - Set TOTAL_SLEEPTIME_DURING_KILL to a notable number of seconds
  #          to check whether the sub processes would actually be granted
  #          this number of seconds before getting killed. This is not set by
  #          default to avoid slowing down the CI.
  my $sub_process = Mojo::IOLoop::ReadWriteProcess->new(
    kill_sleeptime              => 0.01,
    sleeptime_during_kill       => 0.01,
    max_kill_attempts           => 1,
    separate_err                => 0,
    blocking_stop               => 1,
    kill_whole_group            => 1,
    total_sleeptime_during_kill => $ENV{TOTAL_SLEEPTIME_DURING_KILL} // 0.05,
    code                        => sub {
      $SIG{TERM} = 'IGNORE';
      setpgrp(0, 0);
      exec(perl => $test_script);
    })->start();

  # wait until the sub process changes its process group
  # note: Otherwise it still has the process group of this unit test and calling
  #       stop would also stop the test itself.
  my $test_gpid       = getpgrp(0);
  my $sub_process_pid = $sub_process->pid;
  sleep 0.1 while $test_gpid == getpgrp($sub_process_pid);

  $sub_process->stop();
  is $sub_process->is_running, 0, 'process is shut down via kill_whole_group';
};

subtest process_debug => sub {
  my $buffer;
  local $ENV{MOJO_PROCESS_DEBUG} = 1;

  {
# We have to unload and load it back from memory to enable debug. (the ENV value is considered only in compile-time)
    open my $handle, '>', \$buffer;
    local *STDERR = $handle;
    delete $INC{'Mojo/IOLoop/ReadWriteProcess.pm'};
    eval "no warnings; require Mojo::IOLoop::ReadWriteProcess";    ## no critic
    Mojo::IOLoop::ReadWriteProcess->new(
      code                  => sub { 1; },
      kill_sleeptime        => 0.01,
      sleeptime_during_kill => 0.01
    )->start()->stop();
  }

  like $buffer, qr/Fork: \{/,
    'setting MOJO_PROCESS_DEBUG to 1 enables debug mode when forking
process';

  undef $buffer;
  {
    open my $handle, '>', \$buffer;
    local *STDERR = $handle;
    delete $INC{'Mojo/IOLoop/ReadWriteProcess.pm'};
    eval "no warnings; require Mojo::IOLoop::ReadWriteProcess";    ## no critic
    Mojo::IOLoop::ReadWriteProcess->new(
      execute               => "$FindBin::Bin/data/process_check.sh",
      kill_sleeptime        => 0.01,
      sleeptime_during_kill => 0.01,
    )->start()->stop();
  }

  like $buffer, qr/Execute: .*process_check.sh/,
'setting MOJO_PROCESS_DEBUG to 1 enables debug mode when executing external process';
};

subtest 'process_args' => sub {
  my $code = sub {
    shift; 
    print $_.$/ for(@_);
  };

  my $p = Mojo::IOLoop::ReadWriteProcess->new($code, args => '0' )->start->wait_stop();
  is($p->read_all_stdout(), "0$/", '1) False scalar value was given as args.');

  $p = Mojo::IOLoop::ReadWriteProcess->new($code)->args('0')->start->wait_stop();
  is($p->read_all_stdout(), "0$/", '2) False scalar value was given as args.');

  $p = Mojo::IOLoop::ReadWriteProcess->new($code, args => [(0..3)] )->start->wait_stop();
  is($p->read_all_stdout(), "0$/1$/2$/3$/", '1) Args given as arrayref.');

  $p = Mojo::IOLoop::ReadWriteProcess->new($code)->args([(0..3)])->start->wait_stop();
  is($p->read_all_stdout(), "0$/1$/2$/3$/", '2) Args given as arrayref.');
};

subtest 'process in process' => sub {
    my $p = process(sub {
        is( process(execute => '/usr/bin/true')->quirkiness(1)->start()->wait_stop()->exit_status(), 0, 'process(execute) from process(code) -- retval check true');
        is( process(execute => '/usr/bin/false')->quirkiness(1)->start()->wait_stop()->exit_status(), 1, 'process(execute) from process(code) -- retval check false');
        is( process(sub { print 'sub-sub-process'})->start()->wait_stop()->read_all_stdout, 'sub-sub-process', 'process(code) works from process(code)');
        print 'DONE';
    })->start()->wait_stop();

    is ($p->read_all_stdout(), 'DONE', "Use ReadWriteProcess inside of ReadWriteProcess(code=>'')");
};

subtest 'execute exeption handling' => sub {
    throws_ok {
        process(execute => '/I/do/not/exist')->start()->wait_stop()->exit_status();
    } qr%/I/do/not/exist%, 'Execute throw exception, if executable does not exists';

    my $p = process(execute => 'sleep 0.2')->start();
    attempt {
        attempts  => 20,
        condition => sub { defined($p->exit_status)},
    };
    is ($p->is_running(), 0, 'Process not running');
    is ($p->exit_status(), 0, 'Exit status is 0');
};

done_testing;
