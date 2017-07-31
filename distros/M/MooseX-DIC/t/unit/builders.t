#!/usr/bin/perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::RealBin/../../local/lib/perl5";
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/builders/lib";

use Test::Spec;
use Try::Tiny;
use MooseX::DIC qw/build_container/;

describe 'A Moose DI container,' => sub {

	my $container;

	describe 'given a fixed scanpath,' => sub {

		before all => sub {
			$container = build_container( scan_path => ["$FindBin::RealBin/builders/lib"] );
		};

		it 'should provide a service with the Moose factory' => sub {
			my $service = $container->get_service('Test1');
			ok(defined($service));
		};

		it 'should provide a service with the Factory factory' => sub {
			my $service = $container->get_service('Test2');

			ok(defined($service));
		};

	};

};

runtests unless caller;
