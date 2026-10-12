use v5.32;
use warnings;

use Test2::V0;

use Term::Fabulous::Enum::WebColor;

my $WebColor = 'Term::Fabulous::Enum::WebColor';

subtest 'items' => sub {
	my @all = $WebColor->values;
	is scalar(@all),  148,         'the 148 CSS named colors';
	is $all[0]->name, 'AliceBlue', 'alphabetical, AliceBlue first';
	isa_ok $WebColor->Tomato, 'Term::Fabulous::Color';
	is [ $WebColor->Tomato->to_rgba ],        [ 255, 99, 71,  255 ], 'Tomato is opaque #ff6347';
	is [ $WebColor->RebeccaPurple->to_rgba ], [ 102, 51, 153, 255 ], 'RebeccaPurple from CSS Color Level 4';
	is $WebColor->Grey->rgb_int,              $WebColor->Gray->rgb_int, 'Gray and Grey name the same value';
	ref_is $WebColor->from_name('SteelBlue'), $WebColor->SteelBlue, 'from_name returns the singleton';
	is $WebColor->from_name('steelblue'),      undef, 'from_name is case sensitive';
	is $WebColor->Red->with_alpha(128)->alpha, 128,   'derived colors are plain Term::Fabulous::Color objects';
};

done_testing;
