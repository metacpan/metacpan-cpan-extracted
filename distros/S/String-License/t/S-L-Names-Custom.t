use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.7.0';

use Log::Any::Test;
use Log::Any qw($log);

use String::License::Naming::Custom;

plan 4;

subtest 'default' => sub {
	my $obj = String::License::Naming::Custom->new;
	isa_ok $obj, ['String::License::Naming'], 'object is instantiated';
	is [ $obj->list_schemes ], [];
	like [ $obj->list_licenses ], bag {
		item 'MIT';
		item 'Perl';
		all_items mismatch qr/^Expat$/i;
	};
	is [ $obj->add_scheme('debian') ], [qw( debian )],
		'schemes extended';
};

subtest 'none' => sub {
	my $obj = String::License::Naming::Custom->new( schemes => [] );
	isa_ok $obj, ['String::License::Naming'], 'object is instantiated';
	is [ $obj->list_schemes ], [];
	like [ $obj->list_licenses ], bag {
		item 'MIT';
		item 'Perl';
		all_items mismatch qr/^Expat$/i;
	};
	is [ $obj->add_scheme('debian') ], [qw( debian )],
		'schemes extended';
};

subtest 'spdx' => sub {
	my $obj = String::License::Naming::Custom->new( schemes => ['spdx'] );
	isa_ok $obj, ['String::License::Naming'], 'object is instantiated';
	is [ $obj->list_schemes ], [qw( spdx )];
	like [ $obj->list_licenses ], bag {
		item 'MIT';
		all_items mismatch qr/^Expat$/i;
	};
	is [ $obj->add_scheme('debian') ], [qw( debian spdx )],
		'schemes extended';
};

subtest 'debian' => sub {
	my $obj = String::License::Naming::Custom->new( schemes => ['debian'] );
	isa_ok $obj, ['String::License::Naming'], 'object is instantiated';
	is [ $obj->list_schemes ], [qw( debian )];
	like [ $obj->list_licenses ], bag {
		item 'Expat';
		item 'Perl';
		all_items mismatch qr/^MIT$/i;
	};

	# TODO: maybe use Test::Carp
	#is [ $obj->add_scheme('debian') ], [ qw( debian ) ], 'schemes extended';
};

done_testing;
