# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; $num_tests = 6; print "1..$num_tests\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::Ping::External qw(ping);
$loaded = 1;
print "ok 1\n";

$Net::Ping::External::DEBUG_OUTPUT = 1;
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

%test_names = (1 => "use Net::Ping::External qw(ping)",
	       2 => "ping(host => '127.0.0.1')",
	       3 => "ping(host => '127.0.0.1', timeout => 5)",
	       4 => "ping(host => 'some.non.existent.host.')",
	       5 => "ping(host => '127.0.0.1', count => 10)",
	       6 => "ping(host => '127.0.0.1', size => 32)"
	      );

@passed = ();
@failed = ();
push @passed, 1 if $loaded;
push @failed, 1 unless $loaded;

my $output_test_2;
my $exit_test_2;
my $error_test_2;

eval { $ret = ping(host => '127.0.0.1') };
if (!$@ && $ret) {
  print "ok 2\n";
  push @passed, 2;
}
else {
  print "not ok 2\n";
  push @failed, 2;
  $output_test_2 = $Net::Ping::External::LAST_OUTPUT;
  $exit_test_2 = $Net::Ping::External::LAST_EXIT_CODE;
  if ($@) {
    $error_test_2 = $@;
  }
}

eval { $ret = ping(host => '127.0.0.1', timeout => 5) };
if (!$@ && $ret) {
  print "ok 3\n";
  push @passed, 3;
} 
else {
  print "not ok 3\n";
  push @failed, 3;
}

sub inexistent_domain_do_not_resolve {
  use Socket;
  return 1 unless inet_aton('some.non.existent.host.');
  return 0;
}

if (inexistent_domain_do_not_resolve()) {
  eval { $ret = ping(host => 'some.non.existent.host.') };
  if (!$@ && !$ret) {
    print "ok 4\n";
    push @passed, 4;
  }
  else {
    print "not ok 4\n";
    push @failed, 4;
  }
} else {
  push @passed, 4;
  print "ok 4 #skipped\n";
}

eval { $ret = ping(host => '127.0.0.1', count => 2) };
if (!$@ && $ret) {
  print "ok 5\n";
  push @passed, 5;
}
else {
  print "not ok 5\n";
  push @failed, 5;
}

eval { $ret = ping(host => '127.0.0.1', size => 32) };
if (!$@ && $ret) {
  print "ok 6\n";
  push @passed, 6;
}
else {
  print "not ok 6\n";
  push @failed, 6;
}

print "\nRunning a more verbose test suite.";
print "\n-------------------------------------------------\n";
print "Net::Ping::External version: ", $Net::Ping::External::VERSION, "\n";
print scalar(@passed), "/$num_tests tests passed.\n\n";

if (@passed) {
  print "Successful tests:\n";
  foreach (@passed) {
    print "$test_names{$_}\n";
  }
}

if (@failed) {
  print "\nFailed tests:\n";
  foreach (@failed) {
    print "$test_names{$_}\n";
  }
}

my @output = `$^X -v`;
my $a='';
$a.= "\nOperating system according to perl: ".$^O."\n";
if ($^O ne 'MSWin32') {
  $a.= "Operating system according to `uname -a` (if available):\n";
  $a.= `uname -a`;
}
$a.= "Perl version: ";
$a.= @output[1..1];
if ($^O ne 'MSWin32') {
  $a.= "Ping location: ".`which ping`;
}
$a.= "Ping help: ";
my $ping=($^O eq 'Netbsd'?Net::Ping::External::_locate_ping_netbsd():'ping');
my $usage='';
if ($^O eq 'gnukfreebsd') {
  $usage = '--help';
}
$a.= `$ping $usage 2>&1`;
$a.="\n";
if (@failed and $failed[0]==5 and lc($^O) eq 'linux') {
 $a.="-\nping -c 1 some.non.existent.host\n";
 $a.=`ping -c 1 some.non.existent.host`;
 $a.="\n-\n";
}
if (@failed and $failed[0]==2) {
 $a.="-\nresults for test 2:\n";
 $a.="exit code for test 2: $exit_test_2\n";
 $a.="output for test 2: $output_test_2" if defined $output_test_2;
 $a.="\$\@ for test 2: $error_test_2" if $error_test_2;
 $a.="\n-\n";
}

open A,'>NPE.out';
print A $a;
close A;
print $a;
print "-------------------------------------------------\n";
print "If any of the above tests failed, please e-mail the bits between the dashed\n";
print "lines or content of 'NPE.out' to alexchorny AT gmail.com This will help me in\n";
print "fixing this code for maximum portability to your platform. Thanks!\n";

print "\nTests: ".(@failed?"fail":"ok")."\n";
exit (@failed?1:0);

