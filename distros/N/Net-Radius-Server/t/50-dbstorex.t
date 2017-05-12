#!/usr/bin/perl
# $Id: 50-dbstorex.t 109 2009-10-17 22:00:16Z lem $

use strict;
use warnings;

use Test::More qw/no_plan/;

use MLDBM::Sync;
use MLDBM qw/DB_File Storable/;
use Test::Exception;
use File::Find::Rule;
use Net::Radius::Packet;
use Net::Radius::Dictionary;
use Net::Radius::Server::DBStore;
use Net::Radius::Server::Base ':set';

my $dir       = "test-$$";
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

# These are the "extended" methods we will be testing
can_ok($obj, $_) for qw/
    internal_tie
    hashref
    frozen
    /;

# We will use this hash and function for testing
my %tied_hash = ();
my $f = undef;

# Now try with a workable database - but not created...
$obj->param([ 'MLDBM::Sync', $gooddb]);
$obj->frozen(0);
lives_ok(sub { $f = $obj->mk }, 'mk() with good parameters');

# Check what the factory returns
isa_ok($f, 'CODE');

# Now try again, using the external hash, without tying
$obj->hashref(\%tied_hash);
$obj->internal_tie(0);

$obj->param([ 'MLDBM::Sync', $gooddb]);
lives_ok(sub { $f = $obj->mk }, 'mk() with external hash');

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

# At this point the database should NOT exist as we have not tied...
ok(! -f $gooddb, "no database due to no tie()");

# Verify that we stored what we requested in the hash database.

ok(exists($tied_hash{$key}),
   'stored a tuple using ' . $key);

is(scalar(keys %tied_hash), 1, 
   'correct number of tuples in the external hash');

# Now verify the contents...
my $recovered = $tied_hash{$key};
my %expected = map { $_ => $params{$_} } @attrs;
is_deeply($recovered, \%expected, 'recovered data');

is(tied(%tied_hash), undef, "tie has not occurred yet");

# Now we will repeat the process, but requesting an internal tie() to
# be performed.

%tied_hash = ();
$obj->internal_tie(1);
lives_ok(sub { $f = $obj->mk }, 'mk() with good parameters');

# Check what the factory returns
isa_ok($f, 'CODE');

$f->(\%params);

# At this point the database should NOT exist as we have not tied...
ok(-f $gooddb, "database is there because of the tie()");

# Verify that we stored what we requested in the hash database.

ok(exists($tied_hash{$key}),
   'stored a tuple using ' . $key);

is(scalar(keys %tied_hash), 1, 
   'correct number of tuples in the external hash');


__DATA__

# This is a reduced test dictionary. Note that we will only need
# to test very simple packets.

ATTRIBUTE	User-Name		1	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
ATTRIBUTE	NAS-Port		5	string
ATTRIBUTE	Acct-Session-Id		44	string

VENDOR          Test                    42

ATTRIBUTE       Attr                    2       string Test
