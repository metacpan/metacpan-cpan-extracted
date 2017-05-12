use t::Utils;
use Test::More;
use SWFEditor;

note('get_jpeg_alpha(): test');

my $expect = get_file_contents('/image/jpeg002.jpg');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $got = $swfed->get_jpeg_data(1);
    is ($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $got = $swfed->get_jpeg_data(1);
    is ($got, $expect, '');
};

done_testing();
