# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "could not load Net::Connection::Sniffer::Report\nnot ok 1\n" unless $loaded;}

use Net::Connection::Sniffer::Report qw(
	sync
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 027;
foreach my $dir (qw(tmp)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
     /.+/;              # allow for testing with -T switch
      unlink "$dir/$&";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;       # remove files of this name as well
}

sub ok {
  print "ok $test\n";
  ++$test;
}

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

my $path = './tmp';
my $file = $path .'/testfile';

my $now = next_sec();

## test 2	should return immediately if no directory
print "got: $_, exp: undefined\nnot "
	if ($_ = sync($file,0,5));
&ok;

## test 3	check that there was no delay
my $then = $now;
$now = time;
print 'delayed ', ($now - $then), " seconds\nnot "
	unless $now == $then;
&ok;

## test 4	check that there was no alarm
print $@,"\nnot "
	if $@;
&ok;

mkdir $path,0755;

## test 5	timeout on no file
print "got: $_, exp: undefined\nnot "
	if ($_ = sync($file,0,2));
&ok;

## test 6	check for timeout
print "did not get expected timeout\nnot "
	unless $@ && $@ =~ /timeout/;
&ok;

## test 7	create test file
$now = next_sec();
$file = $path .'/testfile';
open(F,'>'. $file) or
	print "could not open '$file' for testing\nnot ";
&ok;

close F;

## test 8	return ctime
my $ctime = sync($file,1,5);
print "got: $ctime, exp: $now\nnot "
	unless $ctime == $now;
&ok;

## test 9	timeout on no update
print "got: $_, exp: undefined\nnot "
	if ($_ = sync($file,$ctime,2));
&ok;

## test 10	check for timeout
print "did not get expected timeout\nnot "
	unless $@ && $@ =~ /timeout/;
&ok;

## test 11	check for update
$now = next_sec();
if (my $pid = fork) {
  print "got: $_, exp: ", ($now + 1), "\nnot "
	unless ($_ = sync($file,$ctime,5));
  waitpid($pid,0);
}
else {
  next_sec($now);
  open(F,'>'. $file) or die "bad oops!";
  close F;
  exit 0;
}
&ok;
