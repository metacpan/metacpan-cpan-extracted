use t::Utils;
use Test::More;
use SWFEditor;

note('replace_bitmap_data width');

my $expect = get_file_contents('/swf/bitmap004.swf');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $d2    = get_file_contents('/resource/negimiku001.png24');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->set_shape_adjust_mode_rect_resize();
    $swfed->replace_bitmap_data({ width => 108 }, \$d2, undef, { rgb15 => 1 });
    my $got = $swfed->output();
    is ($got, $expect, 'bitmap004.phpt');
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $d2    = get_file_path('/resource/negimiku001.png24');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->set_shape_adjust_mode_rect_resize();
    $swfed->replace_bitmap_data({ width => 108 }, $d2, undef, { rgb15 => 1 });
    my $got = $swfed->output();
    is ($got, $expect, 'bitmap004.phpt');
};

done_testing();
