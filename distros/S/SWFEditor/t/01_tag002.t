use t::Utils;
use Test::More;
use SWFEditor;

note('replace_tag_data_by_cid');

my $expect = get_file_contents('/swf/tag002.swf');

tests {
    my $d1    = get_file_contents('/resource/negimiku.swf');
    my $d2    = get_file_contents('/resource/saitama-3.bits');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->replace_tag_data_by_cid(3, \$d2);
    my $got = $swfed->output();
    is ($got, $expect, 'tag002.phpt');
};

tests {
    my $d1    = get_file_path('/resource/negimiku.swf');
    my $d2    = get_file_path('/resource/saitama-3.bits');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->replace_tag_data_by_cid(3, $d2);
    my $got = $swfed->output();
    is ($got, $expect, 'tag002.phpt');
};

done_testing();
