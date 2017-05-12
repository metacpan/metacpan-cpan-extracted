use t::Utils;
use Test::More;
use SWFEditor;

note('convert_bitmap_data_to_jpeg_tag(): test');

my $expect = get_file_contents('/swf/convert001.swf');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->convert_bitmap_data_to_jpeg_tag();
    my $got = $swfed->output();
    is ($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->convert_bitmap_data_to_jpeg_tag();
    $swfed->convert_bitmap_data_to_jpeg_tag();
    my $got = $swfed->output();
    is ($got, $expect, '');
};

done_testing();
