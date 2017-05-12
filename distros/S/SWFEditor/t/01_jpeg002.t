use t::Utils;
use Test::More;
use SWFEditor;

note('replace_jpeg_data test with surplus data at tail');

my $expect = get_file_contents('/swf/jpeg002.swf');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $d2    = get_file_contents('/resource/5.jpg').'ILOVEYOU';
    my $swfed = SWFEditor->new();
    $swfed->set_shape_adjust_mode_rect_resize();
    $swfed->input(\$d1);
    $swfed->replace_jpeg_data(1, \$d2);
    my $got = $swfed->output();
    is ($got, $expect, 'jpeg001.phpt');
};

done_testing();
