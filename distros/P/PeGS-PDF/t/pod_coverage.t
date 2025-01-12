use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

my @ignore = qw(
	arrow_angle
	arrow_factor
	arrow_length
	black_bar_height
	box_height
	connector_height
	font_height
	font_size
	font_width
	get_hash_lengths
	get_list_height
	get_list_width
	lines_xy
	make_anonymous_hash
	make_array
	make_circle
	make_collection_bar
	make_hash
	make_list
	make_magic_circle
	make_pointy_box
	make_reference
	make_reference_arrow
	make_reference_icon
	make_regular_polygon
	make_scalar
	make_text_box
	minimum_scalar_width
	padding_factor
	pointy_width
	stroke_width
	x_padding
	y_padding
	);

all_pod_coverage_ok(
	{ trustme => \@ignore }
	);
																						 
																						 
																						 
																						 
