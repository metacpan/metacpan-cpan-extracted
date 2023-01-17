use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.7.0';

use Log::Any::Test;
use Log::Any qw($log);

use String::License::Naming::SPDX;

plan 1;

subtest 'default' => sub {
	my $obj = String::License::Naming::SPDX->new;
	isa_ok $obj, ['String::License::Naming'], 'object is instantiated';
	is [ $obj->list_schemes ], ['spdx'];
	like [ $obj->list_licenses ], bag {
		item 'MIT';
		item 'Perl';
		all_items mismatch qr/^Expat$/i;
	};
};

done_testing;
