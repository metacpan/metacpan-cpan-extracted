use Test::More tests => 41;

use IO::File;
use Net::Radius::Packet;
use Net::Radius::Dictionary;
use Net::Radius::Server::Base qw/:set/;

# Init the dictionary for our test run...

BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	User-Password		2	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
EOF

    close $fh;
    mkdir './logs';
};

END { 
    unlink 'dict.' . $$; 
    # Attempt to remove remaining logs...
    eval { unlink File::Find::Rule->file->in('./logs') };
    rmdir './logs'; 
};

use_ok('Net::Radius::Server::Dump');

my $d = Net::Radius::Server::Dump->new({});

# Class hierarchy and contents
isa_ok($d, 'Exporter');
isa_ok($d, 'Class::Accessor');
isa_ok($d, 'Net::Radius::Server');
isa_ok($d, 'Net::Radius::Server::Set');

can_ok($d, 'new');
can_ok($d, 'log');
can_ok($d, 'log_level');
can_ok($d, 'mk');
can_ok($d, '_set');
can_ok($d, 'result');
can_ok($d, 'basepath');
can_ok($d, 'basename');
can_ok($d, 'description');
like($d->description, qr/Net::Radius::Server::Dump/, 
     "Description contains the class");
like($d->description, qr/dump\.t/, "Description contains the filename");
like($d->description, qr/:\d+\)$/, "Description contains the line");

# Now test the factory
my $method = $d->mk();
is(ref($method), "CODE", "Factory returns a coderef/sub");

# Invocation with trivial matches
is($method->(), NRS_SET_CONTINUE, "Default set return value");

# Build a request and test it is ok
my $q = new Net::Radius::Packet;
my $dic = new Net::Radius::Dictionary "dict.$$";
isa_ok($q, 'Net::Radius::Packet');
isa_ok($dic, 'Net::Radius::Dictionary');
$q->set_dict($dic);
$q->set_code("Access-Request");
$q->set_attr("User-Name" => 'FOO@MY.DOMAIN');
$q->set_attr("NAS-IP-Address" => "127.0.0.1");

my $r = new Net::Radius::Packet;
isa_ok($r, 'Net::Radius::Packet');
$r->set_dict($dic);
$r->set_code("Access-Accept");

# Now test the invocation passing some parameters
is($method->( { peer_addr => '10.10.10.10', 
		peer_port => 9999, port => 1812,
		secret => 'foo', request => $q, response => $r } ), 
   NRS_SET_CONTINUE, 
   "Base invocation - Default result");

SKIP: 
{
    skip 'Needs File::Find::Rule for remaining tests',
    17 unless use_ok('File::Find::Rule');

    # Our last invocation should have left an empty dir, as no
    # entries where created

    my @dumps = File::Find::Rule
	->file()
	->in('./logs');
    
    is(@dumps, 0, 'No dumps on uninitialized object');

    # Now we will produce a dump and check its contents
    skip 'Needs Test::File::Contents for remaining tests',
    15 unless use_ok('Test::File::Contents');

    skip 'Needs Test::Warn for remaining tests',
    14 unless use_ok('Test::Warn');

    # Add a basepath property and try again our dump
    $d->basepath('./logs');
    is($method->( { peer_addr => '10.10.10.10', 
		    peer_port => 9999, port => 1812,
		    request => $q, response => $r } ), 
       NRS_SET_CONTINUE, 
       "Set basepath property");

    is(File::Find::Rule->file->in($d->basepath), 1, 'First dump');

    $d->result(NRS_SET_DISCARD);
    is($method->( { peer_addr => '10.10.10.10', 
		    peer_port => 9999, port => 1812,
		    request => $q, response => $r } ), 
       NRS_SET_DISCARD, 
       "Set basepath and result property");

    is(@dumps = File::Find::Rule->file->in($d->basepath), 2, 'Second dump');

    # Verify the file contents and naming structure
    for my $f (@dumps)
    {
	like($f, qr!^logs/packet-\d+-\d+$!, 'Correct naming structure');
	file_contents_like($f, qr/(?ms)^\*\*\* RADIUS Request:\s*$/, 
			   'Request header in the dump');
	file_contents_like($f, qr/(?ms)^\*\*\* RADIUS Response:\s*$/, 
			   'Response header in the dump');
	file_contents_like($f, qr/(?ms)^\s+User-Name:\s/, 
			   'Radius attribute present');
	file_contents_like($f, qr/(?ms)^Code:\s+Access-Accept\s*$/, 
			   'Radius response code present');
	unlink $f;
    }
};
