use strict;
use warnings;
use Test::More;

my @modules = qw(
  POE::Component::Github
  POE::Component::Github::Request::Role
  POE::Component::Github::Request::Commits
  POE::Component::Github::Request::Issues
  POE::Component::Github::Request::Users
  POE::Component::Github::Request::Repositories
  POE::Component::Github::Request::Network
  POE::Component::Github::Request::Object
);

plan tests => scalar @modules;
use_ok($_) for @modules;
