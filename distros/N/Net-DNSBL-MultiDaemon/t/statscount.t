# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..31\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNSBL::Utilities qw(
	write_stats
	statinit
	cntinit
	list2hash
	DO
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

umask 027;
foreach my $dir (qw(tmp)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;       # remove files of this name as well
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

my $dir = './tmp';
mkdir $dir,0755;

my $config = './local/test.conf';
my $sfile = $dir .'/stats.tst';

## test 2-4	suck in and check config file

my $DNSBLS = DO($config);
print "could not open configuration file $config\nnot "
	unless $DNSBLS;
&ok;

print "missing configuration file variables domain1.com, domain2.net\nnot "
	unless exists $DNSBLS->{'domain1.com'} && exists $DNSBLS->{'domain2.net'};
&ok;

my $Dkeys = keys %$DNSBLS;
print "got: $Dkeys, exp: 5, bad key count\nnot "
	unless $Dkeys == 5;
&ok;

## test 5	generate count stats hash
my %count;
cntinit($DNSBLS,\%count);
print "got: $_, exp: 5, bad key count\nnot "
	unless ($_ = keys %count) == 5;
&ok;

## test 6-7	check valid count keys
foreach( qw( domain1.com domain2.net ) ) {
  unless (exists $count{"$_"} &&
	  defined $count{"$_"} &&
	  $count{"$_"} == 0) {
    print "missing or undefined key $_\nnot "
  }
  &ok;
}

## test 8	read and check statistics time
my $now = &next_sec();
my $date = localtime($now);
my $statime = statinit($sfile,\%count);
print "got: $statime\nexp: $date\nnot "
	unless $statime =~ /$date/;
&ok;

## test 9-10	re-check valid count keys
foreach( qw( domain1.com domain2.net ) ) {
  unless (exists $count{"$_"} &&
	  defined $count{"$_"} &&
	  $count{"$_"} == 0) {
    print "missing or undefined key $_\nnot "
  }
  &ok;
}

## test 11	re-check key count
print "got: $_, exp: 5, bad key count\nnot "
	unless ($_ = keys %count) == 5;
&ok;

## test 12	generate stats file with bogus entry
$count{'domain1.com'} = 45;
$count{'unknown.org'} = 33;
$count{'domain2.net'} = 100;
$now = &next_sec();
my $update = localtime($now);
write_stats($sfile,\%count,$statime);
print "could not open $sfile\nnot "
	unless open(S,$sfile);
&ok;

my $sftext;
## test 13	get test file text
{
  undef local $/;
  $sftext = <S>;
}
close S;

my $expected = qq
|# last update $update
# stats since $date
100	domain2.net
45	domain1.com
33	unknown.org
0	BlackList
# 178	total rejects
#
0	WhiteList
0	Passed
|;

print "got:
$sftext
exp:
$expected\nnot "
	unless $sftext eq $expected;
&ok;

## test 14	start over with %count
cntinit($DNSBLS,\%count);
print "got: $_, exp: 5, bad key count\nnot "
	unless ($_ = keys %count) == 5;
&ok;

##	add country codes
my @cc = qw( cc1 cc2 );
list2hash(\@cc,\%count);

## test 15-16	check valid count keys
foreach( qw( domain1.com domain2.net ) ) {
  unless (exists $count{"$_"} &&
	  defined $count{"$_"} &&
	  $count{"$_"} == 0) {
    print "missing or undefined key $_\nnot "
  }
  &ok;
}

## test 17	read and check statistics time, should be what was in the file
$now = &next_sec();
$statime = statinit($sfile,\%count);
print "got: $statime\nexp: $date\nnot "
	unless $statime =~ /$date/;
&ok;

## test 18	re-check key count
print "got: $_, exp: 7, bad key count\nnot "
	unless ($_ = keys %count) == 7;
&ok;

## test 19-20	check valid count keys
foreach( qw( domain1.com domain2.net ) ) {
  unless (exists $count{"$_"} &&
	  defined $count{"$_"} &&
	  $count{"$_"} > 1) {
    print "missing or undefined key $_\nnot "
  }
  &ok;
}

## test 21	check specific count values
print "got: domain1.com => $_, exp: 45\nnot "
	unless ($_ = $count{"domain1.com"}) == 45;
&ok;

## test 22	check specific count values
print "got: domain2.net => $_, exp: 100\nnot "
	unless ($_ = $count{"domain2.net"}) == 100;
&ok;

## test 23	update counts and re-write stats file
foreach(keys %count) {
  $count{"$_"} += 5;
}

$count{cc2} += 1;

$now = next_sec();
$update = localtime($now);
write_stats($sfile,\%count,$statime);
print "could not open $sfile\nnot "
	unless open(S,$sfile);
&ok;

## test 24	get test file text
{
  undef local $/;
  $sftext = <S>;
}
close S;

$expected = qq
|# last update $update
# stats since $date
105	domain2.net
50	domain1.com
6	cc2
5	cc1
5	BlackList
# 171	total rejects
#
5	WhiteList
5	Passed
|;

print "got:
$sftext
exp:
$expected\nnot "
	unless $sftext eq $expected;
&ok;

## test 25-31
my %reload = qw(
	domain1.com	0
	domain2.net	0
	cc1		0
	cc2		0
	BlackList	0
	WhiteList	0
	Passed		0
);
statinit($sfile,\%reload);

foreach(sort keys %count) {
  print "exp: $_ => $count{$_}, got: $reload{$_}\nnot "
	unless $count{$_} == $reload{$_};
  &ok;
}
