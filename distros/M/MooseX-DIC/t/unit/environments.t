#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::RealBin/../../local/lib/perl5";
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/environments/lib/common";
use lib "$FindBin::RealBin/environments/lib/pro";
use lib "$FindBin::RealBin/environments/lib/test";

use Test::Spec;
use Log::Log4perl ':easy';
use MooseX::DIC qw/build_container/;

describe 'A Moose DI container,' => sub {

	my $container;

	before all => sub {
		Log::Log4perl->easy_init($ERROR);	
	};

	describe 'given a fixed scanpath with environments,' => sub {

		before all => sub {
			$container = build_container( 
				scan_path => [
					"$FindBin::RealBin/environments/lib/common",
					"$FindBin::RealBin/environments/lib/pro",
					"$FindBin::RealBin/environments/lib/test"
				],
				environment => 'test'
			);
		};

		it 'should return the test impl correctly' => sub {
			my $service = $container->get_service('Service1');
			is(ref $service,'Service1TestImpl');
		};

		it 'should return a default impl if no test impl is found' => sub {
			my $service = $container->get_service('Service2');
			is(ref $service,'Service2DefaultImpl');
		};

		it 'should complain if it doesnt find an impl in test or default envs' => sub {
			my $service = trap { $container->get_service('Service3') };
			my $exception = $trap->die;
			is(ref $exception,'MooseX::DIC::UnregisteredServiceException');
		};

	};

};

runtests unless caller;
