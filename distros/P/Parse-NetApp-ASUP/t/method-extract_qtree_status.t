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
$ret = $pna->extract_qtree_status();
length($ret) eq '757' ? ok(1) : ok(0);
md5_hex($ret) eq 'e066663921b6881bdf30787032448a24' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== QTREE-STATUS =' ? ok(1) : ok(0);

### examples/7.0.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_qtree_status();
length($ret) eq '467' ? ok(1) : ok(0);
md5_hex($ret) eq '2ff2c6cc44953cc29aacc35438b81178' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== QTREE-STATUS =' ? ok(1) : ok(0);

### examples/7.0.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_qtree_status();
length($ret) eq '790' ? ok(1) : ok(0);
md5_hex($ret) eq '42e34517cf013627c10e52a3b0efbb63' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== QTREE-STATUS =' ? ok(1) : ok(0);

### examples/7.0.3/asup04.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.0.3/asup04.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.0.3' ? ok(1) : ok(0);

print "VER: $ver / 7.0.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_qtree_status();
length($ret) eq '5169' ? ok(1) : ok(0);
md5_hex($ret) eq 'e4390f467c2878908f3e0d4191e7349f' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== QTREE-STATUS =' ? ok(1) : ok(0);

### examples/7.2.3/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_qtree_status();
length($ret) eq '1610' ? ok(1) : ok(0);
md5_hex($ret) eq '4999f48f9d13c4a3f2ba9a7dbdb4123c' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== QTREE-STATUS =' ? ok(1) : ok(0);

### examples/7.2.3/asup02.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup02.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_qtree_status();
length($ret) eq '561' ? ok(1) : ok(0);
md5_hex($ret) eq 'c5f00806e980d324ba17e210932310b5' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== QTREE-STATUS =' ? ok(1) : ok(0);

### examples/7.2.3/asup03.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/7.2.3/asup03.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '7.2.3' ? ok(1) : ok(0);

print "VER: $ver / 7.2.3\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_qtree_status();
length($ret) eq '1383' ? ok(1) : ok(0);
md5_hex($ret) eq 'dc5fda1ed508cdf3c68f8b1c642436bd' ? ok(1) : ok(0);
substr($ret,0,20) eq '===== QTREE-STATUS =' ? ok(1) : ok(0);

### examples/8.1/asup01.txt

($asup,$pna,$ret,$ver) = (undef,undef,undef,undef);
$pna = Parse::NetApp::ASUP->new();
$asup = read_file('examples/8.1/asup01.txt');
$ret = $pna->load($asup);
$ret == 1 ? ok(1) : ok(0);
$ver = $pna->asup_version();
$ver eq '8.1' ? ok(1) : ok(0);

print "VER: $ver / 8.1\n" unless $ENV{AUTOMATED_TESTING};
$ret = $pna->extract_qtree_status();
length($ret) eq '0' ? ok(1) : ok(0);
md5_hex($ret) eq 'd41d8cd98f00b204e9800998ecf8427e' ? ok(1) : ok(0);
substr($ret,0,20) eq '' ? ok(1) : ok(0);
system("ps -o rss -p $$") unless $ENV{AUTOMATED_TESTING};


### End
BEGIN { plan tests => 40 };
