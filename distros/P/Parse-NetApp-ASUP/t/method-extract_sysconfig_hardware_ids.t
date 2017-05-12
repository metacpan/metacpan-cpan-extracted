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
$ret = $pna->extract_sysconfig_hardware_ids();
length($ret) eq '120' ? ok(1) : ok(0);
md5_hex($ret) eq '51c29c6776d297d1c67e0646225ea152' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SYSCONFIG HARD' ? ok(1) : ok(0);

### examples/7.0.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_sysconfig_hardware_ids();
length($ret) eq '120' ? ok(1) : ok(0);
md5_hex($ret) eq '51c29c6776d297d1c67e0646225ea152' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SYSCONFIG HARD' ? ok(1) : ok(0);

### examples/7.0.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_sysconfig_hardware_ids();
length($ret) eq '92' ? ok(1) : ok(0);
md5_hex($ret) eq '30219e461d4ef6b0dfd6ef13abd0afe9' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SYSCONFIG HARD' ? ok(1) : ok(0);

### examples/7.0.3/asup04.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup04.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_sysconfig_hardware_ids();
length($ret) eq '92' ? ok(1) : ok(0);
md5_hex($ret) eq '30219e461d4ef6b0dfd6ef13abd0afe9' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SYSCONFIG HARD' ? ok(1) : ok(0);

### examples/7.2.3/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_sysconfig_hardware_ids();
length($ret) eq '137' ? ok(1) : ok(0);
md5_hex($ret) eq 'e2c8433ab69d86a4ee6cead9b8f15817' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SYSCONFIG HARD' ? ok(1) : ok(0);

### examples/7.2.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_sysconfig_hardware_ids();
length($ret) eq '92' ? ok(1) : ok(0);
md5_hex($ret) eq '821bb12c075f57372f1bdb77e047eaa3' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SYSCONFIG HARD' ? ok(1) : ok(0);

### examples/7.2.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_sysconfig_hardware_ids();
length($ret) eq '172' ? ok(1) : ok(0);
md5_hex($ret) eq '9caf678d006093a78d92d2821a529fd1' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SYSCONFIG HARD' ? ok(1) : ok(0);

### examples/8.1/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/8.1/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '8.1' ? ok(1) : ok(0);

print "VER: $ver / 8.1\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_sysconfig_hardware_ids();
length($ret) eq '0' ? ok(1) : ok(0);
md5_hex($ret) eq 'd41d8cd98f00b204e9800998ecf8427e' ? ok(1) : ok(0);
substr($ret,0,20) eq '' ? ok(1) : ok(0);
system("ps -o rss -p $$") unless $ENV{AUTOMATED_TESTING};


### End
BEGIN { plan tests => 40 };
