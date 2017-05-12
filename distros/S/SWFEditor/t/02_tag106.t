use t::Utils;
use Test::More;
use SWFEditor;

note('replace_tag_contents_by_cid(): test');

my $expect = get_file_contents('/swf/tag106.swf');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $d2    = get_file_contents('/tag/contents/saitama.tag.contents.2');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->replace_tag_contents_by_cid(1, \$d2);
    my $got = $swfed->output();
    is_deeply($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $d2    = get_file_path('/tag/contents/saitama.tag.contents.2');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->replace_tag_contents_by_cid(1, $d2);
    my $got = $swfed->output();
    is_deeply($got, $expect, '');
};

done_testing();
