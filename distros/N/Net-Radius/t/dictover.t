#!/usr/bin/perl

# Test the overriding of specific entries

# $Id: dictover.t 27 2006-08-09 16:00:01Z lem $

use IO::File;
use Test::More;
use Data::Dumper;
use Net::Radius::Dictionary;

my $dictfile = "dict$$.tmp";
my $overfile = "over$$.tmp";

END 
{
    unlink $dictfile, $overfile;
};

my @dicts = ();
my @refs = ();

{
    local $/ = "EOD\n";
    @dicts = map { (s/EOD\n$//, $_)[1] } <DATA>;
};

$refs[0] = bless {
    'vsattr'	=> {},
    'rattr'	=> {},
    'vendors'	=> {},
    'rvsaval'	=> {},
    'val'	=> {},
    'rvsattr'	=> {},
    'attr'	=> {},
    'rval'	=> {},
    'vsaval'	=> {}
}, 'Net::Radius::Dictionary';

$refs[1] = bless {
    'vsattr' => {
	'9' => {
	    'Cisco-AVPair' => ['1', 'string' ],
	    'cisco-thing' => ['2', 'string' ]
	    }
    },
    'rattr' => {
	'1' => ['User-Name', 'string'],
	'23' => ['Framed-IPX-Network', 'ipaddr'],
	'10' => ['Framed-Routing', 'integer']
	},
	    'vendors' => {
		'Cisco' => '9'
		},
		    'rvsaval' => {},
		    'val' => {},
		    'rvsattr' => {
			'9' => {
			    '1' => ['Cisco-AVPair', 'string'],
			    '2' => ['cisco-thing', 'string']
			    }
		    },
    'attr' => {
	'Framed-IPX-Network' => ['23', 'ipaddr'],
	'Framed-Routing' => ['10', 'integer'],
	'User-Name' => ['1', 'string']
	},
	    'rval' => {},
	    'vsaval' => {}
}, 'Net::Radius::Dictionary';

sub _write
{
    my $dict = shift;
    my $fh = new IO::File;
    $fh->open($dictfile, "w") or diag "Failed to write dict $dictfile: $!";
    print $fh $dict;
    $fh->close;
}

plan tests => 27 * scalar @dicts;

my $fh = new IO::File;
$fh->open($overfile, "w") or 
    diag "Failed to create dictionary override file $overfile: $!";
print $fh <<EOF;
ATTRIBUTE	User-Name		255	ipaddr
VENDOR		Cisco			254
ATTRIBUTE	Cisco-AVPair		253	string		Cisco
VENDORATTR	253	cisco-thing	252	string
EOF
    ;
$fh->close;

for my $i (0 .. $#dicts)
{

    _write $dicts[$i];

    my $d;

    eval { $d = new Net::Radius::Dictionary $dictfile; };

    isa_ok($d, 'Net::Radius::Dictionary');
    ok(!$@, "No errors during parse");
    diag $@ if $@;
    
    for my $k (keys %{$refs[$i]})
    {
	ok(exists $d->{$k}, "Element $k exists in the object");
	is_deeply($d->{$k}, $refs[$i]->{$k}, "Same contents in element $k");
    }

    eval { $d->readfile($overfile); };
    ok(!$@, "No errors during parse of override dictionary");
    diag $@ if $@;

    is($d->attr_num('User-Name'), 255,
       'Correct number of overriden User-Name');

    is ($d->attr_name(255), 'User-Name',
	'Correct name for User-Name overriden attribute code');

    is($d->attr_type('User-Name'), 'ipaddr',
       'Correct type of overriden User-Name');

    is($d->vendor_num('Cisco'), 254,
       'Correct overriding of vendor code');

    is ($d->vsattr_num(254, 'Cisco-AVPair'), 253,
	'Correct overriding of VSA Attribute name');

    is ($d->vsattr_name(254, 253), 'Cisco-AVPair',
	'Correct overriding of VSA Attribute number');
}

__END__
# Empty dictionary
EOD
# Sample dictionary
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	Framed-Routing		10	integer
ATTRIBUTE	Framed-IPX-Network	23	ipaddr
VENDOR		Cisco		9
ATTRIBUTE	Cisco-AVPair		1	string		Cisco
VENDORATTR	9	cisco-thing	2	string
