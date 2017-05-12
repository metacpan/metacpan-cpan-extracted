#!/usr/bin/perl

use Test::More tests => 26;

use IO::Prompt;
use Net::Radius::Server::Base qw/:match/;

unless ($ENV{NRS_INTERACTIVE})
{
    diag(<<EOF);


This test includes an interactive component. To enable it,
set the environment variable \$NRS_INTERACTIVE to some true
value.


EOF
}

use_ok('Net::Radius::Server::Match::LDAP');

# Create an empty/trivial matcher
my $m = Net::Radius::Server::Match::LDAP->new
    ({});

# Class hierarchy and contents
isa_ok($m, 'Exporter');
isa_ok($m, 'Class::Accessor');
isa_ok($m, 'Net::Radius::Server');
isa_ok($m, 'Net::Radius::Server::Match');
isa_ok($m, 'Net::Radius::Server::Match::LDAP');

can_ok($m, 'mk');
can_ok($m, 'new');
can_ok($m, 'log');
can_ok($m, 'log_level');
can_ok($m, '_match');
can_ok($m, 'ldap_uri');
can_ok($m, 'ldap_opts');
can_ok($m, 'authenticate_from');
can_ok($m, 'bind_dn');
can_ok($m, 'bind_opts');
can_ok($m, 'tls_opts');		# Not currently implemented
can_ok($m, 'search_opts');
can_ok($m, 'store_result');
can_ok($m, 'max_tries');

can_ok($m, 'description');
like($m->description, qr/Net::Radius::Server::Match::LDAP/, 
     "Description contains the class");
like($m->description, qr/ldap\.t/, "Description contains the filename");
like($m->description, qr/:\d+\)$/, "Description contains the line");

# Testing this factory requires a live LDAP server...

# XXX - sleep seems to be the only semi-reliable way to sync the prompts
sleep 1;
diag("\nThe following tests require access to a live LDAP server.");
if ($ENV{NRS_INTERACTIVE} and prompt(q{Run this test? [y/n]: }, -yes))
{
    sleep 1;
    diag("\nWe need a live LDAP server to connect to");
    my $host = prompt(q{Hostname or URI: });
    $m->ldap_uri("$host");

    diag "Will connect to " . $m->ldap_uri;

    sleep 1;
    diag("\nWe need a DN to attempt to bind");
    my $dn = prompt(q{DN: });

    sleep 1;
    diag("\nWe may need a password to bind (blank for anon bind)");
    my $pass = prompt(q{Pasword:}, -e => '*');
    $m->bind_dn("$dn");
    $m->bind_opts([ "$pass" ? (password => "$pass") : (noauth => 1) ]);
    
  TODO:
    {
	local $TODO = 'Need to figure out some universal queries';

	my $method = $m->mk();
	is(ref($method), "CODE", "Factory returns a coderef/sub");
	
	$m->search_opts([ scope => 'sub' , 
			  filter => "(dn=$dn)", 
			  sizelimit => 1 ]);
	# Invocation with trivial matches
	is($method->( { foo => 42 } ), NRS_MATCH_OK, 
	   "No conditions: Should match");
    };
}
else
{
  SKIP: { skip 'Interactive tests skipped or no live LDAP server supplied', 
	  2 };
}


