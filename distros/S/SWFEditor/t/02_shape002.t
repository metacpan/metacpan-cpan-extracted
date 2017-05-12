use t::Utils;
use Test::More;
use SWFEditor;

note('replace_shape_data(): test');

my $expect = get_file_contents('/swf/shape002.swf');

tests {
    my $d1    = get_file_contents('/resource/negimiku.swf');
    my $d2    = get_file_contents('/shape/colorformat.shape.8');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->replace_shape_data(6, \$d2);
    my $got = $swfed->output();
    is ($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/negimiku.swf');
    my $d2    = get_file_path('/shape/colorformat.shape.8');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->replace_shape_data(6, $d2);
    my $got = $swfed->output();
    is ($got, $expect, '');
};

done_testing();
