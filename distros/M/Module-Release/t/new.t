#!/usr/bin/perl
use strict;
use warnings;

use Test::More 1.0;

use lib qw(t/lib);
require 'setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create object with no parameters
{
my $release = $class->new( quiet => 1 );
isa_ok( $release, $class );
}

done_testing();
