use t::Utils;
use Test::More;
use SWFEditor;

note('set_compress_level(): test');

my $expect = get_file_contents('/swf/compress001.swf');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $d2    = get_file_contents('/resource/negimiku001.png');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $image_id = 1;
    $swfed->set_compress_level(9);
    $swfed->replace_png_data($image_id, \$d2);
    my $got = $swfed->output();
    is ($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $d2    = get_file_path('/resource/negimiku001.png');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $image_id = 1;
    $swfed->set_compress_level(9);
    $swfed->replace_png_data($image_id, $d2);
    my $got = $swfed->output();
    is ($got, $expect, '');
};

done_testing();
