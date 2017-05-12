use t::Utils;
use Test::More;
use SWFEditor;

note('replaceBitmapData select bitmap from defineshape fillstyles');

my $expect = get_file_contents('/swf/bitmap006.swf');

tests {
    my $d1    = get_file_contents('/resource/colorformat.swf');
    my $d2    = get_file_contents('/resource/negimiku001.png');
    my $swfed = SWFEditor->new();
    $swfed->set_shape_adjust_mode_matrix_rescale();
    $swfed->input(\$d1);
    my $image_cond = 6;
    $swfed->replace_bitmap_data($image_cond, \$d2);
    my $got = $swfed->output();
    is ($got, $expect, 'bitmap006.phpt');
};

tests {
    my $d1    = get_file_path('/resource/colorformat.swf');
    my $d2    = get_file_path('/resource/negimiku001.png');
    my $swfed = SWFEditor->new();
    $swfed->set_shape_adjust_mode_matrix_rescale();
    $swfed->input($d1);
    my $image_cond = 6;
    $swfed->replace_bitmap_data($image_cond, $d2);
    my $got = $swfed->output();
    is ($got, $expect, 'bitmap006.phpt');
};

done_testing();
