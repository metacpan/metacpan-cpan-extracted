
# $Id: 00-load.t 91 2009-09-17 21:02:08Z lem $

use Test::More;

my @modules = qw/
Net::Radius::Server
Net::Radius::Server::NS
Net::Radius::Server::Base
Net::Radius::Server::Rule
Net::Radius::Server::Dump
Net::Radius::Server::Set
Net::Radius::Server::PAM
Net::Radius::Server::Match
Net::Radius::Server::DBStore
Net::Radius::Server::Match::LDAP
Net::Radius::Server::Match::Simple
Net::Radius::Server::Set::Simple
Net::Radius::Server::Set::Proxy
Net::Radius::Server::Set::Replace
	/;

plan tests => scalar @modules;

my @ok = grep { use_ok($_) } @modules;
BAIL_OUT("One or more modules failed to load") unless @ok == @modules;


