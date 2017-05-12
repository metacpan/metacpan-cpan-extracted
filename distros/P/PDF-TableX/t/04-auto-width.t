#!perl -T

use Test::More tests => 2;

use PDF::TableX;
use PDF::API2;

my $table = PDF::TableX->new(2,2);
my $pdf = PDF::API2->new();
$pdf->mediabox('a4');
my $page = $pdf->page;

$table
	->padding(10)
	->text_align('justify')
	->font_size(8)
	->border_width(0);

my $texts = [];
while (<DATA>) {
		push @{$texts}, $_;
}

$table->[0][0]
	->content($texts->[0])
	->background_color('red');
$table->[0][1]->content($texts->[1]);
$table->[1][0]->content($texts->[2]);
$table->[1][1]
	->content($texts->[3])
	->background_color('red');

$table->draw($pdf, $page);
$pdf->saveas('t/04-auto-width.pdf');

is($table->[0][1]->content(), $texts->[1]);
is($table->[1][0]->content(), $texts->[2]);

diag( "Testing PDF::TableX $PDF::TableX::VERSION, Perl $], $^X" );

done_testing;

__DATA__
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
