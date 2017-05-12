#!/usr/bin/perl
use Test;
BEGIN { plan tests => 64 };
use PostScript::File 0.12 qw(check_file);
use PostScript::Graph::Paper 0.10;
ok(1); # module found

sub array_cmp ($$) {
    my ($a, $b) = @_;
    return 0 if (@$a != @$b);
    for (my $i = 0; $i <= $#$a; $i++) {
	return 0 if ($a->[$i] != $b->[$i]);
    }
    return 1;
}
# Expects two array refs
# Return true if contents are the same

my $gp = new PostScript::Graph::Paper(
	    layout  => {
		heading  => "Bar chart",
		right_edge => 250,
		top_edge   => 500,
		key_width  => 100,
	    },
	    x_axis => {
		labels => [ "First bar",
			    "Second bar",
			    "Third bar" ],
	    },
	    y_axis => {
		low    => 123,
		high   => 456.7,
		title  => "Readings",
	    },
	);
ok($gp); # object created

my $name = "t/03pa-barchart";
$gp->output( $name );
ok(1); # survived so far
ok($gp->layout_left_edge(), 37);
ok($gp->layout_bottom_edge(), 37);
ok($gp->layout_right_edge(), 250);
ok($gp->layout_top_edge(), 500);
ok($gp->layout_right_margin(), 15);
ok($gp->layout_top_margin(), 5);
ok($gp->layout_spacing(), 0);
ok($gp->layout_dots_per_inch(), 300);
ok($gp->layout_heading(), 'Bar chart');
ok($gp->layout_heading_height(), 27);
ok($gp->layout_key_width(), 100);
ok($gp->layout_background(), 1);
ok($gp->layout_color(), 0.5);
ok($gp->layout_heavy_color(), 0.5);
ok($gp->layout_mid_color(), 0.5);
ok($gp->layout_light_color(), 0.5);
ok($gp->layout_heavy_width(), 0.75);
ok($gp->layout_mid_width(), 0.5);
ok($gp->layout_light_width(), 0.25);
ok($gp->layout_font(), 'Helvetica');
ok($gp->layout_font_size(), 10);
ok($gp->layout_font_color(), 0);
ok($gp->layout_heading_font(), 'Helvetica-Bold');
ok($gp->layout_heading_font_size(), 12);
ok($gp->layout_heading_font_color(), 0);
ok($gp->x_axis_low(), 0);
ok($gp->x_axis_high(), 3);
ok($gp->x_axis_width(), 67);
ok($gp->x_axis_height(), 68);
ok($gp->x_axis_label_gap(), 30);
ok($gp->x_axis_smallest(), 0.72);
ok($gp->x_axis_title(), '');
ok($gp->x_axis_font(), 'Helvetica');
ok($gp->x_axis_font_color(), 0);
ok($gp->x_axis_font_size(), 10);
ok($gp->x_axis_mark_min(), 0.5);
ok($gp->x_axis_mark_max(), 8);
ok($gp->x_axis_labels_req(), 3);
ok($gp->x_axis_rotate(), '1');
ok($gp->x_axis_center(), '1');
ok($gp->x_axis_show_lines(), '');
ok($gp->y_axis_low(), 120);
ok($gp->y_axis_high(), 460);
ok($gp->y_axis_width(), 30);
ok($gp->y_axis_height(), 463);
ok($gp->y_axis_label_gap(), 30);
ok($gp->y_axis_smallest(), 0.72);
ok($gp->y_axis_title(), 'Readings');
ok($gp->y_axis_font(), 'Helvetica');
ok($gp->y_axis_font_color(), 0);
ok($gp->y_axis_font_size(), 10);
ok($gp->y_axis_mark_min(), 0.5);
ok($gp->y_axis_mark_max(), 8);
ok($gp->y_axis_labels_req(), 12);
ok($gp->y_axis_rotate(), '');
ok($gp->y_axis_center(), '');
ok($gp->y_axis_show_lines(), '1');
ok(array_cmp([$gp->graph_area()], [67, 105, 134, 468]));
ok(array_cmp([$gp->key_area()],   [149, 37, 249, 468]));
my $psfile = check_file( "$name.ps" );
ok(-e $psfile);
ok( check_filesize($psfile, -s $psfile));	# the chart looks different?
warn "Use ghostview or similar to inspect results file:\n$psfile\n";

sub check_filesize {
    my ($psfile, $pssize) = @_;
    my %fs;
    my $filesizes = 't/filesizes';
    
    if (open(IN, '<', $filesizes)) {
	while (<IN>) {
	    chomp;
	    my ($size, $file) = m/^(\d+)\t(.+)$/;
	    $fs{$file} = $size;
	}
	close IN;
    }
    
    my $exists = $fs{$psfile};
    my $res = ($fs{$psfile} == $pssize);
    $fs{$psfile} = $pssize;

    open(OUT, '>', $filesizes) or die "Unable to write to $filesizes : $!\n";
    while( my ($file, $size) = each %fs ) {
	print OUT "$size\t$file\n" if defined $file and defined $size;
    }
    close OUT;

    return 1 unless $exists;
    return $res;
}
