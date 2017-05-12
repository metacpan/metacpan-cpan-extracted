# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Proc::PidUtil qw(
	get_script_name
);
use Net::Connection::Sniffer qw(:check_config);

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


sub chkit {
  my $conf = shift;
  local *CHILD;
  my $parent = open(CHILD,'-|');
  if ($parent) {
    local $/ = undef;
    my $answer = <CHILD>;
    close CHILD;
    return $answer || '';
  }
  open(STDERR, '>&STDOUT') or die "could not dup STDERR to STDOUT\n";
  check_config($conf);
  print '';			# if it did not die
  exit 0;
}

## test 2	# check BPF missing
my $conf = {};
my $exp = "config: missing hostname in bpf string\n";
print "got: ${_}exp: $exp\nnot "
	unless ($_ = chkit($conf)) eq $exp;
&ok;

## test 3	# corrupt hostname in BPF
$conf->{bpf} = 'host 1.2.3.4.5';
$exp = "config: bad hostname '1.2.3.4.5' in bpf filter string\n";
print "got: ${_}exp: $exp\nnot "
	unless ($_ = chkit($conf)) eq $exp;
&ok;

## test 4	# no interface found
$conf->{bpf} = 'host 255.255.255.254';
$exp  = "config: could not find interface for '255.255.255.254' in bpf string\n";
print "got: ${_}exp: $exp\nnot "
	unless ($_ = chkit($conf)) eq $exp;
&ok;

$conf->{bpf} = 'host 127.0.0.1';	# can always find this one

my $me = get_script_name();
my $medam = ($me =~ /\.pl$/)
        ? $` : $me;

set_me();

## test 5	# check sniffer directory
my $path = './tmp';
$conf->{sniffer} = $path;
$exp = "config: sniffer directory './tmp' missing or not writable\n";
print "got: ${_}exp: $exp\nnot "
	unless ($_ = chkit($conf)) eq $exp;
&ok;

mkdir $path,0755;
open SF,'>'. $path .'/'. $medam .'.stats';
close SF;

## test 6	check port
$conf->{port} = 'bad characters 123';
$exp = "config: invalid port number 'bad characters 123'\n";
print "got: ${_}exp: $exp\nnot "
	unless ($_ = chkit($conf)) eq $exp;
&ok;

$conf->{port} = 65432;

## test 7	invalid dump host
$conf->{host} = '1.2.3.4.5';
$exp = "config: bad dump host '1.2.3.4.5'\n";
print "got: ${_}exp: $exp\nnot "
	unless ($_ = chkit($conf)) eq $exp;
&ok;

## test 8-10	pass all standard hosts
$exp = '';
foreach my $h (qw(
	INADDR_LOOPBACK
	INADDR_ANY
	), '',
  ) {
  $conf->{host} = $h;
  print "host $h\nunexpected: $_\nnot "
	if ($_ = chkit($conf));
  &ok;
}

## test 11	bad allowed value
$conf->{allowed} = [qw(1.2.3.4.5)];
$exp = "config: invalid 'allowed' host or IP '1.2.3.4.5'\n";
print "got: ${_}exp: $exp\nnot "
	unless ($_ = chkit($conf)) eq $exp;
&ok;

## test 12	all allowed
$conf->{allowed} = [qw(192.168.0.1 172.16.0.1)];
$exp = '';
print "allowed unexpected: $_\nnot "
	if ($_ = chkit($conf));
&ok;

## test 13	match, no payload
$conf->{match} = 'some string';
$exp = "config: invalid payload length\n";
print "got: ${_}exp: $exp\nnot "
	 unless ($_ = chkit($conf)) eq $exp;
&ok;

delete $conf->{match};

## test 14	nomatch, no payload
$conf->{nomatch} = 'some string';
$exp = "config: invalid payload length\n";
print "got: ${_}exp: $exp\nnot "
	 unless ($_ = chkit($conf)) eq $exp;
&ok;

## test 15	bad payload length
$conf->{payload} = 38;
$exp = "config: invalid payload length\n";
print "got: ${_}exp: $exp\nnot "
	 unless ($_ = chkit($conf)) eq $exp;
&ok;

## test 16	pass
$conf->{payload} = 37;
$exp = '';
print "unexpected: $_\nnot "
	if ($_ = chkit($conf));
&ok;
