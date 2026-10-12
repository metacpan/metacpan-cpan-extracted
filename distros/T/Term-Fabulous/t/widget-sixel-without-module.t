use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Module::Load::Conditional qw(can_load);

# Hide Imager::File::SIXEL, whether it is installed or not.
BEGIN {
	skip_all 'Imager is not installed' unless can_load( modules => { Imager => 0 } );
	unshift @INC, sub ( $hook, $file ) {
		die "Can't locate Imager/File/SIXEL.pm in \@INC (hidden by the test)\n" if $file eq 'Imager/File/SIXEL.pm';
		return;
	};
}

use InputTest;
use Term::Fabulous::Widget::Sixel;

subtest 'a notice instead of the picture' => sub {
	my $sixel = Term::Fabulous::Widget::Sixel->new( file => "$FindBin::Bin/../examples/images/rainbow_circle.png" );
	my $ui    = layout_ui($sixel);

	is [ map { row_text( $sixel, $_ ) } 0 .. $sixel->rows - 1 ], [ map { sprintf '%-27s', $_ } 'Sixel needs the Perl module', 'Imager::File::SIXEL, which', 'is not installed.' ],
		'naming the missing module';
	is $sixel->sixel_data( shown => [ 0, 0, 1, 1 ], covered => [], cell_size => [ 10, 20 ] ), undef, 'and no picture';
};

done_testing;
