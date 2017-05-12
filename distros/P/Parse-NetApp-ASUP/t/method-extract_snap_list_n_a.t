use File::Slurp;
use Digest::MD5 qw(md5_hex);
use Parse::NetApp::ASUP;
use Test;

my ($asup,$pna,$ret,$ver);

### examples/7.0.3/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_snap_list_n_a();
length($ret) eq '75' ? ok(1) : ok(0);
md5_hex($ret) eq '6bc8ebbd4560de16e5de879286272d3a' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SNAP-LIST-N-A ' ? ok(1) : ok(0);

### examples/7.0.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_snap_list_n_a();
length($ret) eq '75' ? ok(1) : ok(0);
md5_hex($ret) eq '6bc8ebbd4560de16e5de879286272d3a' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SNAP-LIST-N-A ' ? ok(1) : ok(0);

### examples/7.0.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_snap_list_n_a();
length($ret) eq '247' ? ok(1) : ok(0);
md5_hex($ret) eq '31b70f03adf6ac011cd011e1e22584bd' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SNAP-LIST-N-A ' ? ok(1) : ok(0);

### examples/7.0.3/asup04.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup04.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_snap_list_n_a();
length($ret) eq '397' ? ok(1) : ok(0);
md5_hex($ret) eq '4394a8b36bb760fc9a908cd496924be2' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SNAP-LIST-N-A ' ? ok(1) : ok(0);

### examples/7.2.3/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_snap_list_n_a();
length($ret) eq '345' ? ok(1) : ok(0);
md5_hex($ret) eq 'f8d14fc0b5b16b94b1ca9194b773ba32' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SNAP-LIST-N-A ' ? ok(1) : ok(0);

### examples/7.2.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_snap_list_n_a();
length($ret) eq '75' ? ok(1) : ok(0);
md5_hex($ret) eq '6bc8ebbd4560de16e5de879286272d3a' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SNAP-LIST-N-A ' ? ok(1) : ok(0);

### examples/7.2.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_snap_list_n_a();
length($ret) eq '271' ? ok(1) : ok(0);
md5_hex($ret) eq '9f9185b7059f174ddf2de54c97e86f6e' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SNAP-LIST-N-A ' ? ok(1) : ok(0);

### examples/8.1/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/8.1/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '8.1' ? ok(1) : ok(0);

print "VER: $ver / 8.1\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_snap_list_n_a();
length($ret) eq '0' ? ok(1) : ok(0);
md5_hex($ret) eq 'd41d8cd98f00b204e9800998ecf8427e' ? ok(1) : ok(0);
substr($ret,0,20) eq '' ? ok(1) : ok(0);
system("ps -o rss -p $$") unless $ENV{AUTOMATED_TESTING};


### End
BEGIN { plan tests => 40 };
