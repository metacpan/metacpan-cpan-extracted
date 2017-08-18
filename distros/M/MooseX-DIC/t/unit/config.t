#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::RealBin/../../local/lib/perl5";
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/config/only_code";
use lib "$FindBin::RealBin/config/only_file";
use lib "$FindBin::RealBin/config/both";

use Test::Spec;
use Try::Tiny;
use Log::Log4perl ':easy';
use MooseX::DIC qw/build_container/;

describe 'A Moose DI container,' => sub {

	my $container;

	before all => sub {
		Log::Log4perl->easy_init($ERROR);	
	};

	describe 'that only gets its config from scanning code,' => sub {

		before all => sub {
			$container = build_container( scan_path => ["$FindBin::RealBin/config/only_code"] );
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

  describe 'that only gets its config from a config file,' => sub {
    before all => sub {
      $container = build_container( scan_path => [ "$FindBin::RealBin/config/only_file" ] );
    };
    
    it 'should have registered a service' => sub {
			my $service = $container->get_service('Test3');
			ok(defined($service));
		};

		it 'should return a correct implementation for a service' => sub {
			my $test_service = $container->get_service('Test3');
			is(ref $test_service,'Test3Impl');
		};

		it 'should have injected the test3 service into test4' => sub {
			my $test4 = $container->get_service('Test4');
			my $injected_test3 = $test4->dependency1;

			ok(defined($injected_test3));
		};
  };
  
  describe 'that gets its config from both code and config file,' => sub {
    before all => sub {
      $container = build_container( scan_path => [ "$FindBin::RealBin/config/both" ] );
    };
    
    it 'should have registered a service defined in code' => sub {
			my $service = $container->get_service('Test5');
			ok(defined($service));
		};

    it 'should have registered a service defined in the config file' => sub {
			my $service = $container->get_service('Test6');
			ok(defined($service));
		};

		it 'should have injected the service defined in code into the service defined in config file' => sub {
			my $test6 = $container->get_service('Test6');
			my $injected_test5 = $test6->dependency1;

			ok(defined($injected_test5));
		};
  };


};

runtests unless caller;
