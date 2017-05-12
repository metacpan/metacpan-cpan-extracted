#!perl -w
use strict;
# use threads; # TODO use threads instead of fork?
# disabled - causes an error in subtest... Why? Bug in Test::More, or am I doing something wrong?

my $min_tpm=1.02;
eval{use Test::More $min_tpm}; # possible that a earlier version would work
if($@){
  plan skip_all => "Test::More $min_tpm not installed";
}else{
  plan tests => 8;
}

use NET::MitM;
use Carp;

print "="x72,"\n";

# echo server - used in most of our tests
sub echoback($){
  return $_[0];
}
# TODO parameterise port number when test run, or at install time, or something
my $next_port=8000+int(rand(1000));
my $echo_port=$next_port++;

sub pause($)
{
  select(undef,undef,undef,shift);
}

# TODO fail if everything isn't done in - say - 60 seconds.  Kinder than locking up. Can be done using alarm() but makes debugging harder. TODO Maybe put a timeout in mainloop?

sub done()
{
  printf("Process %u has been signalled (@_) - exiting.\n",$$);
  exit();
}
sub abort()
{
  confess sprintf("Process %u has been signalled (@_) - exiting.\n",$$);
  BAIL_OUT("signalled");
  exit();
}
$SIG{TERM}=\&done;
$SIG{ALRM}=\&abort;
$SIG{INT}=\&abort;
$SIG{CLD} = "IGNORE";

sub spawn(&)
{
  my $block=shift;
  my $pid=fork();
  #printf "alarm reset %u/%d\n",$$,alarm(10);
  if(!defined $pid){
    #error
    BAIL_OUT("cannot fork: $!");
  }elsif($pid==0){
    #child
    printf "child %u spawned...\n",$$;
    $block->();
    BAIL_OUT("child unexpectedly exited: $!");
  }else{
    #parent
    pause(.1); # should only need a fraction of a second, probably less
    return $pid;
  }
}

sub is_true($){
  return shift(@_) ? 1 : 0;
}

sub is_false($){
  return shift(@_) ? 0 : 1;
}

subtest "echo server creation" => sub {
  my $echo_server = NET::MitM->new_server($echo_port,\&echoback) || BAIL_OUT("failed to start test server: $!");
  $echo_server->name("echo-server");
  is($echo_server->name(),"echo-server","round trip name()");
  is($echo_server->{local_port_num},$echo_port,"initial setting of local port num"); # Note - encapsulation bypassed
  is($echo_server->{server_callback},\&echoback,"initial setting of callback"); # bypasses encapsulation
};

sub new_echo_server($) {
  my $parallel=shift;
  my $echo_server = NET::MitM->new_server($echo_port,\&echoback) || BAIL_OUT("failed to start test server: $!");
  $echo_server->name("echo-server");
  $echo_server->log_file("echo.log");
  #$echo_server->verbose(2);
  if($parallel){
    # cannot test here because this is executed in a different process
    #ok(is_true($echo_server->parallel()),"parallel defaults to true - for now");
  }else{
    #subtest "set parallel/serial" => sub 
    {
      #ok(is_false($echo_server->serial()),"serial defaults to false - for now");
      #ok(is_true($echo_server->parallel()),"parallel defaults to true - for now");
      $echo_server->serial(1);
      #ok(is_true($echo_server->serial()),"setting serial sets serial");
      #ok(is_false($echo_server->parallel()),"setting serial also sets parallel");
    };
  }
  # side-test of _new_child
  my $new_child=$echo_server->_new_child(); # _new_child will complain (fail) if there are attributes it doesn't expect
  $new_child->name(sprintf "echo-server-child-%u",$$);
  print "go...\n";
  $echo_server->go();
  BAIL_OUT("server->go() should not have returned");
  return "this should not have happened";
}

my $echo_server_pid=spawn(sub{new_echo_server(1)});

# It would be nice to be able to run with old or new Test::More.  It is possible to test for the presence of subtest, for eg "if(defined &Test::More::subtest)..." But there is no obvious mechanism for telling the old Test::More how many tests to expect without confusing the new Test::More. 
subtest 'client <-> server (without MitM)' => sub {
  my $test="direct to server";
  my @clients;
  my $repeats=10; # works for up to just over 1000 on linux, the limit on windows is rather lower
  for (1..$repeats){
    $clients[$_] = my $client = NET::MitM->new_client("localhost",$echo_port);
    $client->name("$test-$_");
    my $response = $client->send_and_receive("1234.$_");
    is($response, "1234.$_", "$test: send and receive a string ($_ of $repeats)");
  }
  for (1..$repeats){
    $clients[$_]->disconnect_from_server();
  }
};

subtest 'MitM with no callbacks' => sub {
  my $port2=$next_port++;
  my $MitM_pid = spawn(
    sub{
      my $mitm = NET::MitM->new('localhost',$echo_port,$port2) || BAIL_OUT("failed to start MitM: $!");
      $mitm->name("MitM-$port2");
      #is($mitm->name(),"MitM-$port2","roundtrip name()");
      $mitm->go();
      BAIL_OUT("MitM->go() should not have returned");
    }
  );
  my $client = NET::MitM->new_client("localhost",$port2);
  $client->name("client-$port2");
  my $response = $client->send_and_receive("232");
  is($response,"232","send and receive a string");
  $client->disconnect_from_server();
  pause(.1); # should only need a fraction of a second
  printf "Signalling MitM: %u\n",$MitM_pid;
  kill 'TERM', $MitM_pid or warn "missed: $!";
};

# note - log1 and log2 are called in the child process, not in the parent - cannot be used to return a value to parent when running in parallel

my @log1=">";
sub log1($)
{
  print "++ log1 called ++\n";
  return shift;
}

my @log2;
sub log2($)
{
  print "++ log2 called ++\n";
  return undef;
}

subtest 'MitM with readonly callbacks'=>sub {
  my $port2=$next_port++;
  my $MitM_pid = spawn(
    sub{
      my $mitm = NET::MitM->new('localhost',$echo_port,$port2) || BAIL_OUT("failed to start MitM: $!");
      $mitm->client_to_server_callback(\&log1);
      $mitm->server_to_client_callback(\&log2);
      $mitm->name("mitm-$port2");
      $mitm->go();
      BAIL_OUT("MitM->go() should not have returned");
    }
  );
  my $client = NET::MitM->new_client("localhost",$port2);
  $client->name("client-$port2");
  my $response = $client->send_and_receive("234");
  is($response,"234","send and receive a string");
  $client->disconnect_from_server();
  pause(.1); # should only need a fraction of a second
  printf "Signalling MitM: %u\n",$MitM_pid;
  kill 'TERM', $MitM_pid or warn "missed: $!";
};

sub manipulate1($)
{
  my $str = shift;
  $str =~ s/a/A/;
  return $str;
}

sub manipulate2($)
{
  my $str = shift;
  $str =~ s/e/E/;
  return $str;
}

sub with_readwrite($){
  my $parallel=shift;
  my $test="MitM with readwrite callbacks - parallel=$parallel";
  my $port2=$next_port++;
  my $MitM_pid = spawn(
    sub{
      my $MitM = NET::MitM->new('localhost',$echo_port,$port2) || BAIL_OUT("failed to start MitM: $!");;
      $MitM->name("mitm-$port2");
      $MitM->server_to_client_callback(\&manipulate1);
      $MitM->client_to_server_callback(\&manipulate2);
      $MitM->parallel(1) if $parallel;
      $MitM->go();
      BAIL_OUT("MitM->go() should not have returned");
    }
  );
  my $client = NET::MitM->new_client("localhost",$port2);
  $client->name("client-$port2");
  my $response = $client->send_and_receive("abc");
  is($response,"Abc","$test: request manipulation");
  $response = $client->send_and_receive("def");
  is($response,"dEf","$test: response manipulation");
  $client->disconnect_from_server();
  pause(.1); # should only need a fraction of a second
  printf "Signalling MitM: %u\n",$MitM_pid;
  kill 'TERM', $MitM_pid or warn "missed: $!";
}

subtest "MitM with readwrite callbacks - serial" => sub {
  with_readwrite(0);
};

subtest "MitM with readwrite callbacks - parallel" => sub {
  with_readwrite(1);
};

{
  my $done=0;

  subtest 'MitM with timer_callback'=>sub {
    my $port2=$next_port++;
    sub do_once(){
      return 0;
    }
    my $mitm = NET::MitM->new('localhost',$echo_port,$port2) || BAIL_OUT("failed to start MitM: $!");
    $mitm->timer_callback(0,\&do_once);
    my ($interval,$callback) = $mitm->timer_callback();
    is($interval,1); # sanity check - mitm disallows an interval of exactly 0
    $mitm->timer_callback(2,\&do_once);
    $mitm->name("mitm-$port2");
    ($interval,$callback) = $mitm->timer_callback();
    is($interval,2);
    is($callback,\&do_once);
    my $t1 = time();
    alarm 5; # if something goes wrong, don't silently hang forever - user may still need to ^C, but at least tell them
    $mitm->go();
    alarm 0;
    my $t2 = time();
    my $t_diff=$t2-$t1;
    # without Time::HiRes, is only accurate to the second, and potentially not even that accurate
    ok($t_diff >= 1, "go() took $t_diff seconds, should take at least 1 second (hopefully, 2)");
    ok($t_diff <= 3, "go() took $t_diff seconds, should take no more than 3 seconds (hopefully, 2)");
    sub do_till_done(){
      return !$done;
    }
    sub set_done(){
      $done=1;
      return shift;
    }
    $mitm->timer_callback(2,\&do_till_done);
    $mitm->server_to_client_callback(\&set_done);
    $mitm->listen();
    my $client = NET::MitM->new_client("localhost",$port2);
    $client->name("client-$port2");
    $client->send_to_server("ping");
    $mitm->timer_callback(.1,\&do_till_done);
    is(scalar(@{$mitm->{children}}),0,"no children yet"); # note - breaks encapsulation
    $mitm->go();
    is(scalar(@{$mitm->{children}}),1,"one child now"); # note - breaks encapsulation
    is($done,1,"do till done");
    my $resp = $client->read_from_server("ping");
    is($resp,"ping","round trip");
    $client->_destroy(); # TODO provide a user callable method? Would need to clean up children - if running in serial
    $mitm->go();
    is(scalar(@{$mitm->{children}}),0,"closing client should terminate children"); # note - breaks encapsulation
    $mitm->_destroy();
    # TODO how to test that all ports have been properly closed? lsof? alloc a file handle and check it has value #4?
  };
}

SKIP: {
  eval { use Time::HiRes qw(time sleep)};
  if($@){
    skip "Time::HiRes, which is not installed, is required for sub-second accuracy of timer_interval. You may still specify fractions of a second, MitM will out by up to a second each time, but it will average out. If this is not precise enough, please install Time::HiRes.\n";
  }
  my $to_go=10;
  subtest 'timer_interval precision'=>sub {
    my $port2=$next_port++;
    my $mitm = NET::MitM->new('localhost',$echo_port,$port2) || BAIL_OUT("failed to start MitM: $!");
    $mitm->verbose(2);
    sub do_til_done(){
      print "done=$to_go\n";
      if(--$to_go>0){
	sleep 0.1;
	return 1;
      }else{
	return 0;
      }
    }
    $mitm->timer_callback(.2,\&do_til_done);
    $mitm->name("mitm-$port2");
    my ($interval,$callback) = $mitm->timer_callback();
    is($interval,.2);
    is($callback,\&do_til_done);
    my $t1 = time();
    $mitm->go();
    my $t2 = time();
    my $t_diff=$t2-$t1;
    # on my boxes, takes ~2.00125 seconds on windows, ~2.00098 on linx. Allow +/- 0.1. It averages out over a long run.
    ok($t_diff >= 1.9 && $t_diff <= 2.1, "go() took $t_diff seconds, should take close to 2 seconds");
  };
}

if(0) # TODO Automated test not working yet - manual testing suggests code works fine
{
  my $test="defrag_delay";
  my $port2=$next_port++;
  sub mark_fragments($){return qq{[$_[0]]}};
  my $MitM_pid = spawn(
    sub{
      my $MitM = NET::MitM->new('localhost',$echo_port,$port2);
      $MitM->name("mitm-$port2");
      $MitM->server_to_client_callback(\&mark_fragments);
      $MitM->client_to_server_callback(\&mark_fragments);
      $MitM->defrag_delay(0);
      $MitM->log_file("defrag.log");
      $MitM->go();
    }
  );
  my $client = NET::MitM->new_client("localhost",$port2);
  $client->name("client-$port2");
  my $delay=0.1; # guess
  for("a".."j"){ # FIXME - only works up to about 10 message, or maybe that is all that makes sense?
    pause($delay);
    $client->sendToServer($_);
  }
  my $response1 = $client->read_from_server(); 
  isnt($response1,"[[abcdefghij]]","$test: test the test case - ensure some fragmentation is occurring so we can prove our 'prevention' is doing something");
  $client->disconnect_from_server();
  pause(.1);
  printf "Signalling MitM: %u\n",$MitM_pid;
  kill 'TERM', $MitM_pid or warn "missed: $!";
  $port2=$next_port++;
  $MitM_pid = spawn(
    sub{
      my $MitM = NET::MitM->new('localhost',$echo_port,$port2);
      $MitM->name("mitm-$port2");
      $MitM->server_to_client_callback(\&mark_fragments);
      $MitM->client_to_server_callback(\&mark_fragments);
      $MitM->defrag_delay(3);
      $MitM->log_file("defrag2.log");
      $MitM->verbose(1);
      $MitM->go();
    }
  );
  $client = NET::MitM->new_client("localhost",$port2);
  $client->name("client-$port2");
  for("a".."j"){
    pause($delay);
    $client->sendToServer($_);
  }
  my $response2 = $client->read_from_server(); # TODO add a timeout :-(
  is($response2,"[[abcdefghij]]","$test: our messages, sent so close together, should have been defragmented into a single message");
  $client->disconnect_from_server();
  pause(.1); # should only need a fraction of a second
  printf "Signalling MitM: %u\n",$MitM_pid;
  kill 'TERM', $MitM_pid or warn "missed: $!";
}

pause(.1); # let children exit - they should already have been signalled
printf "Signalling echo server: %u\n",$echo_server_pid;
print kill('TERM',$echo_server_pid) or warn "Failed to kill echo server\n";
pause(.1); # let echo server die
done_testing(); # not supported by old versions of Test::More

print "="x72,"\n";
