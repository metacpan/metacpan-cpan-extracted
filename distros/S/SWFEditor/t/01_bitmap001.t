use t::Utils;
use Test::More;
use SWFEditor;

note('get_bitmap_size JPG');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $got = $swfed->get_bitmap_size(1);
    is ($got->{width},  108, 'bitmap001.phpt');
    is ($got->{height},  80, 'bitmap001.phpt');
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $got = $swfed->get_bitmap_size(1);
    is ($got->{width},  108, 'bitmap001.phpt');
    is ($got->{height},  80, 'bitmap001.phpt');
};

done_testing();
