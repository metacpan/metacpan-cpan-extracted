use Test2::V0;
use Test2::Tools::Spec;

use Story::Interact;
use Story::Interact::Harness::Test;

use FindBin qw($Bin);

describe 'Simple walk through' => sub {
	my ( $source );
	
	case 'with directory as page source' => sub {
		$source = "$Bin/../../examples/house/";
	};
	
	case 'with SQLite as page source' => sub {
		$source = "$Bin/../../examples/house.sqlite";
	};
	
	tests 'play through with apple' => sub {
		my $harness = Story::Interact::Harness::Test->new(
			page_source => Story::Interact->new_page_source( $source ),
		);
		ok $harness->go( qr/Enter/i ), '--> Enter';
		ok $harness->go( qr/kitchen/i ), '--> Kitchen';
		ok $harness->go( qr/apple/i ), , '--> Pick up apple';
		ok $harness->go( qr/kitchen/i ), '--> Kitchen';
		ok $harness->go( qr/living room/i ), '--> Living room';
		ok $harness->go( qr/bedroom/i ), '--> Bedroom';
		like $harness->page_text, qr/You have been here 0 times/, '... page text ok';
		ok $harness->go( qr/sleep/i ), '--> Sleep';
		like $harness->page_text, qr/You dream about your apple/i, '... page text ok';
	};
	
	tests 'play through without apple' => sub {
		my $harness = Story::Interact::Harness::Test->new(
			page_source => Story::Interact->new_page_source( $source ),
		);
		ok $harness->go( qr/Enter/i ), '--> Enter';
		ok $harness->go( qr/bedroom/i ), '--> Bedroom';
		like $harness->page_text, qr/You have been here 0 times/, '... page text ok';
		ok $harness->go( qr/sleep/i ), '--> Sleep';
		unlike $harness->page_text, qr/You dream about your apple/i, '... page text ok';
	};
};

done_testing;