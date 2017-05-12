use t::Utils;
use Test::More;
use SWFEditor;

note('replace_png_data (transparent)');

my $expect = get_file_contents('/swf/png001.swf');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $d2    = get_file_contents('/resource/negimiku001.png');
    my $swfed = SWFEditor->new();
    $swfed->set_shape_adjust_mode_none();
    $swfed->input(\$d1);
    my $image_id = 1;
    $swfed->replace_png_data($image_id, \$d2);
    my $got = $swfed->output();
    is ($got, $expect, 'png001.phpt');
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $d2    = get_file_path('/resource/negimiku001.png');
    my $swfed = SWFEditor->new();
    $swfed->set_shape_adjust_mode_none();
    $swfed->input($d1);
    my $image_id = 1;
    $swfed->replace_png_data($image_id, $d2);
    my $got = $swfed->output();
    is ($got, $expect, 'png001.phpt');
};

done_testing();
