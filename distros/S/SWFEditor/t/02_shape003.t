use t::Utils;
use Test::More;
use SWFEditor;

note('get_shape_id_list_by_bitmap_ref(): test');

my $expect = { 1 => [2], 3 => [4], 5 => [6] };

tests {
    my $d1    = get_file_contents('/resource/negimiku.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    for (1,3,5) {
        my $got = $swfed->get_shape_id_list_by_bitmap_ref($_);
        is_deeply ($got, $expect->{$_}, '');
    }
};

tests {
    my $d1    = get_file_path('/resource/negimiku.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    for (1,3,5) {
        my $got = $swfed->get_shape_id_list_by_bitmap_ref($_);
        is_deeply ($got, $expect->{$_}, '');
    }
};

done_testing();
