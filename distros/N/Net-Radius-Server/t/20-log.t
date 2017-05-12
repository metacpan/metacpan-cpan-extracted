
# $Id: 20-log.t 25 2006-11-09 18:38:10Z lem $

use Test::More;

my @modules = qw/
Net::Radius::Server::Base
Net::Radius::Server::Rule
Net::Radius::Server::Dump
Net::Radius::Server::Set
Net::Radius::Server::Match
Net::Radius::Server::Match::LDAP
Net::Radius::Server::Match::Simple
Net::Radius::Server::Set::Simple
Net::Radius::Server::Set::Proxy
Net::Radius::Server::Set::Replace
	/;

my $tests = @modules;
plan tests => 10 * $tests;

SKIP: {
    skip 'Failed to load Test::Warn', scalar $tests
	unless eval "use Test::Warn; 1";
    for my $m (@modules)
    {
	use_ok($m);
	my $o = new $m;
	isa_ok($o, $m);
	# Warnings with the default level
	warning_like(sub { $o->log($_, "level-$_") }, qr/level-$_/, 
		     "Level $_ - Def LL") for 1 .. 2;
	warning_is(sub { $o->log($_, "level-$_") }, undef, 
		     "Level $_ - Def LL") for 3 .. 4;
	# Now, set the log_level and verify
	$o->log_level(4);
	warning_like(sub { $o->log($_, "level-$_") }, qr/level-$_/, 
		     "Level $_ - LL 4") for 1 .. 4;
    }
};

