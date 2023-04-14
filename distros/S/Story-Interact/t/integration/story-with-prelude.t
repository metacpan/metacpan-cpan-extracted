use Test2::V0;
use Test2::Tools::Spec;

use Story::Interact;
use Story::Interact::Harness::Test;

use FindBin qw($Bin);

describe 'Simple walk through' => sub {
	
	my $source = Story::Interact::PageSource::Dir->new(
		dir => "$Bin/../../t/share/story-with-prelude/",
	);
	
	tests 'play through' => sub {
		my $harness = Story::Interact::Harness::Test->new( page_source => $source );
		like $harness->page_text, qr/bob says...my name is bob/i, '... page text ok';
	};
};

done_testing;
