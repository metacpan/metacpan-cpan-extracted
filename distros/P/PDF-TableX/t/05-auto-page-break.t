#!perl -T

use Test::More tests => 1;

use PDF::TableX;
use PDF::API2;

my $table = PDF::TableX->new(2,10);
my $pdf = PDF::API2->new();
$pdf->mediabox('a4');
my $page = $pdf->page;

$table
	->padding(10)
	->text_align('left')
	->font_size(12)
	->border_width(2)
	->cycle_background_color('#cccccc', '#efefef')
	->width(150/25.4*72)
	->repeat_header(1);

# make some rows stand out
$table->[3]->border_width(5)->background_color('#99CC66');
$table->[7]->border_width(5)->background_color('#99CC66');

#load texts
my $texts = [];
while (<DATA>) {
		push @{$texts}, $_;
}

for my $i (0..$table->rows-1) {
	for my $j (0..$table->cols-1) {
		$table->[$i][$j]->content( $texts->[($i*2)+$j] );
	}
}

# set header (first row simply)
$table->[0]
	->background_color('#EDBD3E')
	->font('Courier-Bold')
	->font_size(12)
	->font_color('black')
	->text_align('center');
$table->[0][0]
	->content('FIRST COLUMN');
$table->[0][1]
	->content('SECOND COLUMN');

# set column styles
$table->col(1)
	->border_width([0,0,2,2])
	->text_align('right');

$table->draw($pdf, $page);

is($pdf->pages(), 4);

$pdf->saveas('t/05-auto-page-break.pdf');


diag( "Testing PDF::TableX $PDF::TableX::VERSION, Perl $], $^X" );

done_testing;

__DATA__
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tristique ultrices nisl, eget adipiscing dui feugiat quis. Maecenas tincidunt fermentum ligula, a blandit sem tempus convallis. Cras congue arcu et felis consequat condimentum scelerisque nunc faucibus. Quisque vestibulum porttitor ligula, et lobortis leo feugiat et. Nullam eget eros nibh, in adipiscing sem. Phasellus eu magna eu eros vulputate facilisis ut rhoncus metus. Etiam nec vehicula neque. Donec viverra pretium mi vitae imperdiet. Vivamus nec tortor urna. Praesent elementum enim vitae risus scelerisque placerat a eu metus. Vivamus in ultricies arcu.
Aenean orci risus, porttitor ac sodales id, viverra sed purus. Fusce vel lacus ante, vitae volutpat nibh. Nullam bibendum lorem vitae justo tincidunt sit amet posuere purus faucibus. Vivamus posuere posuere tellus, vitae ullamcorper ante venenatis id. Duis lacinia sollicitudin leo vel sollicitudin. Proin vestibulum sapien nec ante commodo blandit. Nullam blandit augue eget orci scelerisque sollicitudin id id lacus. Sed laoreet interdum eros a accumsan. Etiam pretium, leo eu elementum consequat, tellus diam vulputate magna, in suscipit libero arcu ut nulla. Integer a odio nunc, sit amet congue augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean pellentesque cursus ullamcorper. Phasellus ut diam velit, id venenatis magna. Phasellus ultricies mauris et diam dignissim a consequat mi lacinia. Nam congue rutrum libero.