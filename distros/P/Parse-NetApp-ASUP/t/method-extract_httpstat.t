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
$ret = $pna->extract_httpstat();
length($ret) eq '155' ? ok(1) : ok(0);
md5_hex($ret) eq '6e0fe0a8c1d91dbca8139ae14491fc1a' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== HTTPSTAT =====' ? ok(1) : ok(0);

### examples/7.0.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_httpstat();
length($ret) eq '155' ? ok(1) : ok(0);
md5_hex($ret) eq '6e37e533eb75639130d1ef0c5d5a20d3' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== HTTPSTAT =====' ? ok(1) : ok(0);

### examples/7.0.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_httpstat();
length($ret) eq '155' ? ok(1) : ok(0);
md5_hex($ret) eq 'be96ec9e4efc1f29ce704ee17d149be5' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== HTTPSTAT =====' ? ok(1) : ok(0);

### examples/7.0.3/asup04.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup04.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_httpstat();
length($ret) eq '155' ? ok(1) : ok(0);
md5_hex($ret) eq 'ff22d4f2eb322099d75872680b3a22f3' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== HTTPSTAT =====' ? ok(1) : ok(0);

### examples/7.2.3/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_httpstat();
length($ret) eq '155' ? ok(1) : ok(0);
md5_hex($ret) eq '98c26921c5d6377f994ff73d0931bb54' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== HTTPSTAT =====' ? ok(1) : ok(0);

### examples/7.2.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_httpstat();
length($ret) eq '155' ? ok(1) : ok(0);
md5_hex($ret) eq 'c1bc3f7672aa91c3306b75f9c7c7cc9f' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== HTTPSTAT =====' ? ok(1) : ok(0);

### examples/7.2.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_httpstat();
length($ret) eq '152' ? ok(1) : ok(0);
md5_hex($ret) eq '4aed1f93d896e5e87a5a2ea080c15a3c' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== HTTPSTAT =====' ? ok(1) : ok(0);

### examples/8.1/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/8.1/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '8.1' ? ok(1) : ok(0);

print "VER: $ver / 8.1\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_httpstat();
length($ret) eq '0' ? ok(1) : ok(0);
md5_hex($ret) eq 'd41d8cd98f00b204e9800998ecf8427e' ? ok(1) : ok(0);
substr($ret,0,20) eq '' ? ok(1) : ok(0);
system("ps -o rss -p $$") unless $ENV{AUTOMATED_TESTING};


### End
BEGIN { plan tests => 40 };
