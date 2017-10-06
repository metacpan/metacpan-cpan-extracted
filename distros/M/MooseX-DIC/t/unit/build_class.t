#!/usr/bin/perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::RealBin/../../local/lib/perl5";
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/build_class/lib";

use Test::Spec;
use Try::Tiny;
use Log::Log4perl ':easy';
use MooseX::DIC qw/build_container/;

describe 'A Moose DI container,' => sub {

	my $container;

	before all => sub {
		Log::Log4perl->easy_init($ERROR);	
	};

	describe 'given a fixed scanpath,' => sub {

		before all => sub {
			$container = build_container( scan_path => ["$FindBin::RealBin/build_class/lib"] );
		};

		it 'should be capable of building a class with just dependencies' => sub {
			my $built_class = $container->build_class('Test3');
			ok(defined($built_class));
		};

		it 'should have injected correctly the dependencies in the built class' => sub {
			my $built_class = $container->build_class('Test3');
      my $dep1 = $built_class->dependency1;
      my $dep2 = $built_class->dependency2;
			ok(defined($dep1) and defined($dep2));
		};

    it 'should complain if it doesnt find the requested package' => sub {
      trap { $container->build_class('Test4') };
      my $exception = $trap->die;
      ok($exception->isa('MooseX::DIC::PackageNotFoundException'));
    };

    it 'should complain if the requested package is not built with Moose' => sub {
      trap { $container->build_class('Test5') };
      my $exception = $trap->die;
      ok($exception->isa('MooseX::DIC::ContainerException'));
    };

	};

};

runtests unless caller;
