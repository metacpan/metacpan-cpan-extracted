use t::Utils;
use Test::More;
use SWFEditor;

note('is_shape_tag()');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    for (my $seqno = 0; $seqno < @{$swfed->get_tag_list()}; $seqno++) {
        my $data = $swfed->get_tag_data($seqno);
        if ($swfed->is_shape_tag_data(\$data)) {
            my $got = $swfed->get_tag_list()->[$seqno];
            is($seqno,          4,             't/01_isshapetag001.t');
            is($got->{code},    2,             't/01_isshapetag001.t');
            is($got->{tag},     2,             't/01_isshapetag001.t');
            is($got->{tagName}, 'DefineShape', 't/01_isshapetag001.t');
            is($got->{length},  51,            't/01_isshapetag001.t');
            is($got->{detail},  1,             't/01_isshapetag001.t');
        }
    }
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    for (my $seqno = 0; $seqno < @{$swfed->get_tag_list()}; $seqno++) {
        my $data = $swfed->get_tag_data($seqno);
        if ($swfed->is_shape_tag_data(\$data)) {
            my $got = $swfed->get_tag_list()->[$seqno];
            is($seqno,          4,             't/01_isshapetag001.t');
            is($got->{code},    2,             't/01_isshapetag001.t');
            is($got->{tag},     2,             't/01_isshapetag001.t');
            is($got->{tagName}, 'DefineShape', 't/01_isshapetag001.t');
            is($got->{length},  51,            't/01_isshapetag001.t');
            is($got->{detail},  1,             't/01_isshapetag001.t');
        }
    }
};

done_testing();
