use t::Utils;
use Test::More;
use SWFEditor;

note('get_jpeg_alpha(): test');

my $expect = get_file_contents('/alpha/negimiku.alpha.3');

tests {
    my $d1    = get_file_contents('/resource/negimiku.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $got = $swfed->get_jpeg_alpha(3);
    is ($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/negimiku.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $got = $swfed->get_jpeg_alpha(3);
    is ($got, $expect, '');
};

done_testing();
