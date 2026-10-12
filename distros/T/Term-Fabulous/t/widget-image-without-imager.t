use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

# Hide Imager, whether it is installed or not.
BEGIN {
	unshift @INC, sub ( $hook, $file ) {
		die "Can't locate Imager.pm in \@INC (hidden by the test)\n" if $file eq 'Imager.pm';
		return;
	};
}

use Clay::XS qw(sizing_fixed);
use InputTest;
use Term::Fabulous::Widget::Image;

subtest 'a notice instead of the image' => sub {
	my $image  = Term::Fabulous::Widget::Image->new( file   => 'no/such/image.png' );
	my $narrow = Term::Fabulous::Widget::Image->new( base64 => 'aGk=', layout => { sizing => { width => sizing_fixed(20) } } );
	my $ui     = layout_ui( $image, $narrow );

	is [ $image->file, $image->image_width ], [ 'no/such/image.png', undef ], 'the source is kept, but not read';
	is [ map { row_text( $image,  $_ ) } 0 .. $image->rows - 1 ],  [ 'Image needs the Perl module', 'Imager, which is not       ', 'installed.                 ' ], 'the notice at its natural size';
	is [ map { row_text( $narrow, $_ ) } 0 .. $narrow->rows - 1 ], [ 'Image needs the Perl',        'module Imager, which',        'is not installed.   ' ], 'wrapped to the width the layout gives';
};

done_testing;
