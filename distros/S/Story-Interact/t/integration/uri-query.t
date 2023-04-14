use Test2::V0;
use Test2::Tools::Spec;

use Story::Interact;
use Story::Interact::Harness::Test;

use FindBin qw($Bin);

describe 'Simple walk through' => sub {
	
	my ( $choice, $expected );
	my $source = Story::Interact::PageSource::Dir->new(
		dir => "$Bin/../../t/share/uri-query/",
	);
	
	case 'when choosing first option' => sub {
		$choice   = qr/page 1/i;
		$expected = qr/Got ABC[.]/;
	};
	
	case 'when choosing second option' => sub {
		$choice   = qr/page 2/i;
		$expected = qr/Got DEF[.]/;
	};
	
	tests 'play through' => sub {
		my $harness = Story::Interact::Harness::Test->new( page_source => $source );
		ok $harness->go( $choice ), 'make choice';
		like $harness->page_text, $expected, '... page text ok';
	};
};

done_testing;
