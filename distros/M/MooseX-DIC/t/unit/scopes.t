#!/usr/bin/perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::RealBin/../../local/lib/perl5";
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/scopes/lib";

use Test::Spec;
use Log::Log4perl ':easy';
use Try::Tiny;
use MooseX::DIC qw/build_container/;

describe 'A Moose DI container,' => sub {

	my $container;

	before all => sub {
		Log::Log4perl->easy_init($ERROR);	
	};

	describe 'given a fixed scanpath,' => sub {

		before all => sub {
			$container = build_container( scan_path => ["$FindBin::RealBin/scopes/lib"] );
		};

		it 'should provide a singleton scoped service' => sub {
			my $service = $container->get_service('Test1');
			my $service2 = $container->get_service('Test1');
			ok($service == $service2);
		};

		it 'should provide a request scoped service' => sub {
			my $service = $container->get_service('Test2');
			my $service2 = $container->get_service('Test2');

			ok($service != $service2);
		};

		it 'should make a request-injected service available' => sub {
			my $service = $container->get_service('Test3');
			my $dependency1 = $service->dependency1;
			my $dependency2 = $service->dependency1;

			ok($dependency1 != $dependency2);
		};

		it 'should die with config error if trying to request request-injected singleton-scoped object' => sub {
			trap { $container->get_service('Test4'); };
			my $exception = $trap->die;

			is(ref $exception,'MooseX::DIC::ContainerConfigurationException');
		};
	};

};

runtests unless caller;
