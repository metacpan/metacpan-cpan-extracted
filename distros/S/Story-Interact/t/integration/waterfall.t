use Test2::V0;
use Test2::Tools::Spec;

use Story::Interact;
use Story::Interact::Harness::Test;

use FindBin qw($Bin);

describe 'Simple walk through' => sub {
	my ( $source, $has_blah );
	
	case 'with simple page source' => sub {
		$source = Story::Interact::PageSource::Dir->new(
			dir => "$Bin/../../examples/house/",
		);
		$has_blah = 0;
	};
	
	case 'with waterfall page source' => sub {
		my $source1 = Story::Interact::PageSource::Dir->new(
			dir => "$Bin/../../t/share/override/",
		);
		my $source2 = Story::Interact::PageSource::Dir->new(
			dir => "$Bin/../../examples/house/",
		);
		$source = Story::Interact::PageSource::Waterfall->new(
			sources => [ $source1, $source2 ],
		);
		$has_blah = 1;
	};
	
	tests 'play through' => sub {
		my $harness = Story::Interact::Harness::Test->new( page_source => $source );
		ok $harness->go( qr/Enter/i ), '--> Enter';
		ok $harness->go( qr/kitchen/i ), '--> Kitchen';
		ok $harness->go( qr/apple/i ), , '--> Pick up apple';
		ok $harness->go( qr/kitchen/i ), '--> Kitchen';
		ok $harness->go( qr/living room/i ), '--> Living room';
		if ( $has_blah ) {
			like $harness->page_text, qr/Blah blah blah/i, '... page text ok';
		}
		else {
			unlike $harness->page_text, qr/Blah blah blah/i, '... page text ok';
		}
		ok $harness->go( qr/bedroom/i ), '--> Bedroom';
		like $harness->page_text, qr/You have been here 0 times/, '... page text ok';
		ok $harness->go( qr/sleep/i ), '--> Sleep';
		like $harness->page_text, qr/You dream about your apple/i, '... page text ok';
	};
};

done_testing;
