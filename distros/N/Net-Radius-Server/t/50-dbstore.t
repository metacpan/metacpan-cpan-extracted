#!/usr/bin/perl
# $Id: 50-dbstore.t 108 2009-10-17 02:48:38Z lem $

use strict;
use warnings;

use Test::More tests => 64;

use BerkeleyDB;
use Test::Exception;
use File::Find::Rule;
use Storable qw/thaw/;
use Net::Radius::Packet;
use Net::Radius::Dictionary;
use Net::Radius::Server::DBStore;
use Net::Radius::Server::Base ':set';

my $dir       = "test-$$";
my $wrongdb   = $dir . '/wrong/test.db';
my $gooddb    = $dir . '/test.db';
my $dict_name = $dir . '/dictionary';
my $dict_text = join('', <DATA>);
my @attrs     = qw/packet peer_addr peer_host peer_port port/;

sub _cleanup ()
{
    local($^W) = 0;		# Warning within File::Find::Rule when
				# under make test. This gets rid of it.
    
    unlink File::Find::Rule
	->file()
	->in($dir);
    
    rmdir $dir;
}

END { _cleanup };

# Make our sandbox, including our working dictionary.
sub _init () 
{ 
    _cleanup;
    mkdir $dir;
    open DICT, ">", $dict_name
	or die "Failed to create $dict_name: $!\n";
    print DICT $dict_text;
    close DICT;
}

_init;

# Let's start by parsing the dictionary we'll be using for our tests...
my $d = new Net::Radius::Dictionary $dict_name;
isa_ok($d, 'Net::Radius::Dictionary', 'test dictionary');
is($d->attr_num($_->[0]), $_->[1], 'dict: attribute ' . $_->[0])
    for ( [ 'User-Name' => 1 ], [ 'NAS-IP-Address' => 4   ],
	  [ 'NAS-Port'  => 5 ], [ 'Acct-Session-Id' => 44 ]);

# Create a method factory and do some preliminary testing on it
my $obj = new Net::Radius::Server::DBStore({});

isa_ok($obj, $_) for qw/Net::Radius::Server::DBStore 
    Net::Radius::Server::Base
    Class::Accessor
    /;

# These methods must be available for the object
can_ok($obj, $_) for qw/
    key_attrs
    log
    log_level
    pre_store_hook
    mk
    new
    param
    result
    sync
    frozen
    single
    /;

# Trying to ->mk should cause an exception because no DB config has
# been specified, so no tie can happen...

throws_ok { $obj->mk } qr/cannot proceed with no valid param defined/;

# Now let's define a mildly invalid config and see what happens

$obj->param([ 'BerkeleyDB::Hash', -Filename => $wrongdb]);
$obj->log_level(1);		# No logs, thanks.

# Verify the default values for the paramenters before calling ->mk
is_deeply($obj->$_, undef, 'virgin default ' . $_)
    for qw/ key_attrs store sync /;
my $f;

# This should barf because we cannot tie this database...
throws_ok { $f = $obj->mk } qr/unable to tie/;

# Verify the default values for the paramenters after calling ->mk
is_deeply($obj->key_attrs, [ 'NAS-IP-Address', 
                             '|', 
                             'Acct-Session-Id' ], 
	                                          'default key_attrs');
is_deeply($obj->store,     \@attrs,               'default store');
is_deeply($obj->sync,      1,                     'default sync');

# Now try with a workable database - but not created...
$obj->param([ 'BerkeleyDB::Hash', -Filename => $gooddb]);
throws_ok { $f = $obj->mk } qr/unable to tie/;

# Now ask the tie to create missing files...
$obj->param([ 'BerkeleyDB::Hash', -Filename => $gooddb, 
	      -Flags => DB_CREATE ]);
lives_ok(sub { $f = $obj->mk }, 'mk() with good parameters');

# Check what the factory returns
isa_ok($f, 'CODE');

# Fake a call to the method at $f and see what transpires...
# For this we build a slightly incorrect Radius request to
# send in.
my $req = new Net::Radius::Packet $d;
isa_ok($req, 'Net::Radius::Packet', 'fake packet');
$req->set_code          ('Accounting-Request');
$req->set_identifier    (42);
$req->set_authenticator ('deadbeef' x 2);
$req->set_attr          ('User-Name'            => 'lem');
$req->set_attr          ('NAS-IP-Address'       => '127.0.0.1');
$req->set_attr          ('NAS-Port'             => 'Seattle');
$req->set_attr          ('Acct-Session-Id'      => 'Testing-123');
$req->set_vsattr        ('Test', Attr           => 'Foo');

my %params = ( map { $_ => $_ } @attrs );
$params{request} = $req;
$params{packet}  = $params{request}->pack;

my $key = $req->attr('NAS-IP-Address') . '|' . $req->attr('Acct-Session-Id');

$f->(\%params);

# At this point the database should exist.
ok(-f $gooddb, "good database has been created");

# Verify that we stored what we requested in the hash database.
my %stored;
ok(tie(%stored, 'BerkeleyDB::Hash', -Filename => $gooddb),
   'Tying to database for testing');

ok(exists($stored{$key}),
   'stored a tuple using ' . $key);

is(scalar(keys %stored), 1, 'correct number of tuples in the database');

# Now verify the contents...
my $recovered = thaw $stored{$key};
my %expected = map { $_ => $params{$_} } @attrs;
is_deeply($recovered, \%expected, 'recovered data');

# Now, attempt to overwrite this and see if it changes in the database. We
# will reuse everything from the earlier test.
$params{port} = 'New York';
is($f->(\%params), &NRS_SET_CONTINUE, 'default return value for method');

# Basic consistency...
ok(exists($stored{$key}),
   'stored a tuple using ' . $key);
is(scalar(keys %stored), 1, 'correct number of tuples in the database');

# Verify that what was stored matches our latest packet

ok(tie(%stored, 'BerkeleyDB::Hash', -Filename => $gooddb),
   'Re-tying to database for testing');

$recovered = thaw $stored{$key};
%expected = map { $_ => $params{$_} } @attrs;
is_deeply($recovered, \%expected, 'recovered data (rewrite)');

$obj->result(42);
is($f->(\%params), 42, 'can change default result');

# Test we can change the key format to something weirder. This is a
# key that contains delimiters, VSAs and user-defined functions. Also
# test if the callback is actually called back.

my $magic  = 'Set within the coderef';
my $kf = sub 
{ 
    isa_ok($_[0], 'Net::Radius::Server::DBStore', 'class of self');
    isa_ok($_[1], 'BerkeleyDB::Hash',             'class of hash object');
    isa_ok($_[2], 'HASH',                         'tied hash of type');
    isa_ok($_[3], 'HASH',                         'data hash type');
    isa_ok($_[4], 'Net::Radius::Packet',          'request type');
    return $magic; 
};

my $called = 0;
my $hf = sub
{
    isa_ok($_[0], 'Net::Radius::Server::DBStore', 'class of self');
    isa_ok($_[1], 'BerkeleyDB::Hash',             'class of hash object');
    isa_ok($_[2], 'HASH',                         'tied hash of type');
    isa_ok($_[3], 'HASH',                         'data hash type');
    isa_ok($_[4], 'Net::Radius::Packet',          'request type');
    is    ($_[5], $key,                           'passed key');

    # Attempt a live modification of what to store...
    
    $_[3]->{quato} = 'lives!';
    $_[3]->{meme} = { ponies => 'rainbows' };
    my $s = $_[0]->store();
    push @$s, (qw/quato meme/);

    # Let the test harness know we were here...
    $called = 42;
};

$obj->pre_store_hook($hf);
$obj->key_attrs([ 'Acct-Session-Id', '|', 'NAS-Port', '|', 
		  [ Test => 'Attr' ], 'Foo', '|', $kf, '|', 'end' ]);
$key = $req->attr('Acct-Session-Id') . '|' . 'Seattle' . '|' . 'FooFoo' . 
    '|' . $magic . '|end';

lives_ok(sub { $f = $obj->mk }, 'mk() with a complex key_attrs');
is($f->(\%params), 42, 'the non-default result maintains');

is($called, 42, 'pre_store_hook got called');

ok(tie(%stored, 'BerkeleyDB::Hash', -Filename => $gooddb),
   'Re-tying to database for testing custom keys');

$recovered = thaw $stored{$key};
%expected = map { $_ => $params{$_} } @attrs;
$expected{quato} = 'lives!';
$expected{meme} = { ponies => 'rainbows' };
is_deeply($recovered, \%expected, 'recovered data (rewrite + key_attrs)');

_init;

# Test usage by invoking ->mk() directly

throws_ok sub { $f = Net::Radius::Server::DBStore->mk
		    ({
			param => [ 'BerkeleyDB::Hash', -Filename => $gooddb, 
				   -Flags => DB_CREATE ],
		    }); },
    qr/^$/, 'direct invocation of ->mk() does not throw';


lives_ok sub { $f = Net::Radius::Server::DBStore->mk
		   ({
		       param => [ 'BerkeleyDB::Hash', -Filename => $gooddb, 
				  -Flags => DB_CREATE ],
		   }); },
    'direct invocation of ->mk()';

isa_ok($f, 'CODE', 'manufactured method from direct ->mk()');

isnt($f->(\%params), 42, 'the non-default result is lost');

ok(tie(%stored, 'BerkeleyDB::Hash', -Filename => $gooddb),
   'Re-tying yet again');

$key = $req->attr('NAS-IP-Address') . '|' . $req->attr('Acct-Session-Id');
$recovered = thaw $stored{$key};
%expected = map { $_ => $params{$_} } @attrs;
is_deeply($recovered, \%expected, 'recovered data (rw + mk())');

__DATA__

# This is a reduced test dictionary. Note that we will only need
# to test very simple packets.

ATTRIBUTE	User-Name		1	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
ATTRIBUTE	NAS-Port		5	string
ATTRIBUTE	Acct-Session-Id		44	string

VENDOR          Test                    42

ATTRIBUTE       Attr                    2       string Test
