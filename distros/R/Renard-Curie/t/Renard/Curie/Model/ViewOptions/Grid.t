#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Renard::Curie::Model::ViewOptions::Grid;
use Renard::Incunabula::Common::Error;

use lib 't/lib';

subtest "Grid option construction" => sub {
	my @grid_options = (
		{ options => { rows => 1,     columns => 1     }, valid => 1, continuous => 0 },
		{ options => { rows => -1,    columns => 1     }, valid => 0, reason => '-1 number' },
		{ options => { rows => undef, columns => 1     }, valid => 1, continuous => 1 },
		{ options => { rows => 1,     columns => undef }, valid => 1, continuous => 1 },
		{ options => { rows => undef, columns => undef }, valid => 0 , reason => 'both are undef' },

	);

	plan tests => scalar @grid_options;

	for my $option (@grid_options) {
		subtest "Grid option" => sub {
			explain "Try to build", $option->{options};
			if( $option->{valid} ) {
				my $grid_options;
				lives_ok {
					$grid_options = Renard::Curie::Model::ViewOptions::Grid->new(
						$option->{options}
					);
				} "Constructed";
				is( !! $grid_options->is_continuous_view , !! $option->{continuous}, 'Check if continuous view' );
			} else {
				throws_ok {
					Renard::Curie::Model::ViewOptions::Grid->new(
						$option->{options}
					);
				} 'Renard::Curie::Error::ViewOptions::InvalidGridOptions',
					"Invalid options: @{[ $option->{reason} ]}";;
			}
		};
	}
};

done_testing;
