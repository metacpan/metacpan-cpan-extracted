#!/usr/bin/perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::RealBin/../../local/lib/perl5";
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/container/lib";

use Test::Spec;
use MooseX::DIC qw/build_container/;

describe 'A Moose DI container,' => sub {

	my $container;

	describe 'given a fixed scanpath,' => sub {

		before all => sub {
			$container = build_container( scan_path => ["$FindBin::RealBin/container/lib"] );
		};

		it 'should have registered a service' => sub {
			my $service = $container->get_service('Test1');
			ok(defined($service));
		};

		it 'should return a correct implementation for a service' => sub {
			my $test_service = $container->get_service('Test1');
			is(ref $test_service,'Test1Impl');
		};

		it 'should have injected the test1 service into test2' => sub {
			my $test2 = $container->get_service('Test2');
			my $injected_test1 = $test2->dependency1;

			ok(defined($injected_test1));
		};

	};

};

runtests unless caller;
