# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use 5.005;
use ExtUtils::testlib;
BEGIN { $Sys::Signal::Test = 2 }
use Sys::Signal;
$loaded = 1;

eval {   
    my $h = Sys::Signal->set(ALRM => sub { die "ok 1\n" });   
    alarm 1;  
    sleep 2;  
    alarm 0;   
};   
print $@ if $@;  

#my_sighandler will be restored now
eval {
    alarm 1; 
    sleep 2; 
    alarm 0; 
};

print $@ if $@;  

$SIG{ALRM} = sub { die "ok 4\n" };

eval {   
    my $h = Sys::Signal->set(ALRM => sub { die "ok 3\n" });   
    alarm 1;  
    sleep 2;  
    alarm 0;   
};   
print $@ if $@;  

eval {
    alarm 1; 
    sleep 2; 
    alarm 0; 
};

print $@ if $@;  

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

