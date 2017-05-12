# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::Connection::Sniffer::Report qw(
	get_lock
);
$loaded = 1;

print "ok 1\n";

$test = 2;

umask 027;
if (-d 'tmp') {         # clean up previous test runs
  opendir(T,'tmp');
  @_ = grep(!/^\./, readdir(T));
  closedir T;
  foreach(@_) {
    unlink "tmp/$_";
  }
} else {
  mkdir 'tmp', 0750 unless (-e 'tmp' && -d 'tmp');
}

sub ok {
  print "ok $test\n";
  ++$test;
}

############## test file locking #############################
my $filedb = 'tmp/locktmp.file';
my $filetxt = 
'The Quick Brown Fox Jumped 
over the Lazy Dog 1234567890';

my $extra = 
'extra stuff';

## test 2	acquire lock, 5 second timeout
my($lock,$file) = get_lock($filedb,5); 
print $@,"\nnot "
	if $@;
&ok;

## test 3	fail lock
my($lock2,$file2);
eval {
	local $SIG{ALRM} = sub {die "lock2 timeout"};
	alarm 2;
	($lock2,$file2) = get_lock($filedb,5);
	alarm 0;
};
print "unexpected successful lock2\nnot "
	if $@ && $@ =~ /lock2 timeout/;
&ok;

close $file;
close $lock;
