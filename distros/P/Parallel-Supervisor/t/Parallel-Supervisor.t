# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Parallel-Supervisor.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;
BEGIN { use_ok('Parallel::Supervisor') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $P = Parallel::Supervisor->new();

# Test 2: was our object created?
isa_ok($P,"Parallel::Supervisor", "constructor");

# Test 3: can we prepare a child?
ok( $P->prepare("a child","print \"Hello World\"") , "prepare a child" );

# Test 4: create and forget a child task
$P->prepare("b child","print \"Goodnight.\"");
ok($P->forget("b child"), "forget child") ; 

# Test 5: can we get the child struct back from the supervisor?
my %C = %{$P->get_next_ready};
ok($C{id} eq "a child" , "get a child");

# Test 6: can we fork the child?
my $forkpid = fork();
# child process - no testing inside here
if ($forkpid == 0) {
    # tell the child process to do one thing
    close $C{parent_reader};
    select $C{child_writer};
    eval($C{cmd});
    # TODO: sleep 5 # test blocking??
    exit ;
}
# parent process - testing continues

ok(defined $forkpid , "parent sees fork");

# Test 7: can we attach the child?
isnt(undef,$P->attach($C{id},$forkpid) , "attach child");

# Test 8: struct is alive
ok($P->is_attached("a child") , "child is alive" );

# Test 9: Supervisor can return our child pid
my @jobpids = @{$P->get_pids};
ok($jobpids[0] == $forkpid , "get child pid");

#TODO: test whether the pipe is actually non-blocking (i.e. does autoflush() work as expected?)
# Test 10: Open the pipe for reading
close $C{child_writer};

my ($result,$str);
$result =  read $C{parent_reader}, $str, 12;
isnt(undef , $result, "read from child");
#ok(open( CHILDSAYS, "<", $C{parent_reader} ) , "open reader fh");

# Test 11 : child output worked
ok($result != 0 , "child has output");

# Test 12: child returned "Hello World"
ok($str eq "Hello World" , "received child's message");

# Test 13: filehandle can be released
ok(close $C{parent_reader} , "closed parent fh");

# Test 14: detach the child task
ok($P->detach($forkpid) , "detach child") ; 

# Test 15: collection is empty after detach
ok( scalar keys %{$P->structs}   eq 0 , "after detach, ready list is empty") ; 

# Test 16: collection is empty after detach
ok( scalar keys %{$P->processes} eq 0 , "after detach, active list is empty") ; 

# Test 17: collection is empty after detach
ok( scalar keys %{$P->finished}  ge 1 , "after detach, finished structs remain") ; 

# Test 18: collection is empty after detach
$P->forget("a child");
ok( scalar keys %{$P->finished} eq 0 , "after forget, finished structs is empty") ; 

# Test 19: all collections empty after reset - create structs as ready, active, and finished
$P->prepare("c child", "echo foo");
$P->prepare("d child", "echo foo");
$P->attach("d child",4); # bogus PID
$P->prepare("e child", "echo foo");
$P->attach("e child", 5); # bogus PID
$P->detach(5);
$P->reset;
ok( scalar keys %{$P->structs} eq 0 &&
    scalar keys %{$P->processes} eq 0 &&
    scalar keys %{$P->names} eq 0 &&
    scalar keys %{$P->finished} eq 0,
   "after reset, all collections are empty") ; 

# EOF
