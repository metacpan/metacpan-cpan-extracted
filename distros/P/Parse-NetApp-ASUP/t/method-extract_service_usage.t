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
$ret = $pna->extract_service_usage();
length($ret) eq '575' ? ok(1) : ok(0);
md5_hex($ret) eq 'ed45c9a1b49e67bd55cbd069f51f5478' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SERVICE USAGE ' ? ok(1) : ok(0);

### examples/7.0.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_service_usage();
length($ret) eq '575' ? ok(1) : ok(0);
md5_hex($ret) eq '2c33934a1e9afac1919c85c6828b5853' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SERVICE USAGE ' ? ok(1) : ok(0);

### examples/7.0.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_service_usage();
length($ret) eq '577' ? ok(1) : ok(0);
md5_hex($ret) eq 'd904605cf69e1cd2423b4ff2d8c848b2' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SERVICE USAGE ' ? ok(1) : ok(0);

### examples/7.0.3/asup04.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup04.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_service_usage();
length($ret) eq '962' ? ok(1) : ok(0);
md5_hex($ret) eq '163b646e4b67fd9edbdadca930c3227d' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SERVICE USAGE ' ? ok(1) : ok(0);

### examples/7.2.3/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_service_usage();
length($ret) eq '467' ? ok(1) : ok(0);
md5_hex($ret) eq 'b424a895897740eef8d623a3838bf037' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SERVICE USAGE ' ? ok(1) : ok(0);

### examples/7.2.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_service_usage();
length($ret) eq '469' ? ok(1) : ok(0);
md5_hex($ret) eq '14a7f2dfa9a6a8269e303f45465f272e' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SERVICE USAGE ' ? ok(1) : ok(0);

### examples/7.2.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_service_usage();
length($ret) eq '571' ? ok(1) : ok(0);
md5_hex($ret) eq 'fd0fd431761fb5cc2d71b6606581736a' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== SERVICE USAGE ' ? ok(1) : ok(0);

### examples/8.1/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/8.1/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '8.1' ? ok(1) : ok(0);

print "VER: $ver / 8.1\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_service_usage();
length($ret) eq '0' ? ok(1) : ok(0);
md5_hex($ret) eq 'd41d8cd98f00b204e9800998ecf8427e' ? ok(1) : ok(0);
substr($ret,0,20) eq '' ? ok(1) : ok(0);
system("ps -o rss -p $$") unless $ENV{AUTOMATED_TESTING};


### End
BEGIN { plan tests => 40 };
