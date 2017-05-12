use t::Utils;
use Test::More;
use SWFEditor;

note('get_tag_contents_by_cid(): test');

my $expect = get_file_contents('/tag/contents/saitama.tag.contents.1');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $got = $swfed->get_tag_contents_by_cid(1);
    is_deeply($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $got = $swfed->get_tag_contents_by_cid(1);
    is_deeply($got, $expect, '');
};

done_testing();
