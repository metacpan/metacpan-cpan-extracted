use t::Utils;
use Test::More;
use SWFEditor;
use FindBin;

note('replace_png_data(): with opt');

my $expect = get_file_contents('/image/png006.png');

tests {
    my $d1    = get_file_contents('/resource/4color-300.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $got = $swfed->get_png_data(1);
    is ($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/4color-300.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $got = $swfed->get_png_data(1);
    is ($got, $expect, '');
};

done_testing();
