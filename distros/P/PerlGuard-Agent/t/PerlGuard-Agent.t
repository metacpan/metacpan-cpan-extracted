# I have stripped out most of the tests for the initial CPAN release as they are only suitable for development
# Full test suite to follow once we establish which monitoring method to use (Hook::LexWrap may be unsuitable after initial customer testing)

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PerlGuard-Agent.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use FindBin;
# use Mojo::JSON;

use Test::More tests => 6;
BEGIN { use_ok('PerlGuard::Agent') };
BEGIN { use_ok('PerlGuard::Agent::Profile') };
BEGIN { use_ok('PerlGuard::Agent::Output::StandardError') };
# BEGIN { use_ok('PerlGuard::Agent::Frameworks::Mojolicious') };
BEGIN { use_ok('PerlGuard::Agent::Monitors::DBI') };
BEGIN { use_ok('PerlGuard::Agent::Monitors::NetHTTP') };
BEGIN { use_ok('PerlGuard::Agent::Output::PerlGuardServer') };


#########################

my $agent = PerlGuard::Agent->new();
