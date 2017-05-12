# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "could not load Net::Connection::Sniffer::Report\nnot ok 1\n" unless $loaded;}

use Net::Connection::Sniffer::Report qw(
	chkcache
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

my $path = './tmp';
mkdir $path,0755;

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

## test 2	create test file
my $file = $path .'/testfile';
my $now = next_sec();
open(F,'>'. $file) or
	print "could not open '$file' for testing\nnot ";
&ok;

close F;

## test 3	check current timestamp
my $got = chkcache($file);
print "got: $got, exp: $now\nnot "
	unless $got == $now;
&ok;

## test 4	check still current timestamp not expired
my $then = $now;
$now = next_sec($now + 2);
print "got: $got, exp: $then\nnot "
	unless ($got = chkcache($file,3) || 0) == $then;
&ok;

## test 5	check expired
print "got: $got, exp: undefined\nnot "
	if ($got = chkcache($file,2));
&ok;
