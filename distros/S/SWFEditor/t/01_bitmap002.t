use t::Utils;
use Test::More;
use SWFEditor;

note('get_bitmap_size Lossless');

tests {
    my $d1    = get_file_contents('/resource/negimiku.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $got = $swfed->get_bitmap_size(1);
    is ($got->{width},  320, 'bitmap002.phpt');
    is ($got->{height}, 240, 'bitmap002.phpt');
};

tests {
    my $d1    = get_file_path('/resource/negimiku.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $got = $swfed->get_bitmap_size(1);
    is ($got->{width},  320, 'bitmap002.phpt');
    is ($got->{height}, 240, 'bitmap002.phpt');
};

done_testing();
