#!perl

use strict;
use warnings;

use Test::More;

my $pkg = "Perl::Critic::Policy::PreferredModules";

use_ok($pkg);

my $policy = $pkg->can('new')->($pkg);

ok( $policy, "$pkg->new" );
isa_ok( $policy, $pkg );
can_ok( $policy, qw(violates) );

done_testing;
