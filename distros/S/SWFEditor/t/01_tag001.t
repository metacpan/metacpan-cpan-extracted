use t::Utils;
use Test::More;
use SWFEditor;

note('replace_tag_data');

my $expect = get_file_contents('/swf/tag001.swf');

tests {
    my $d1    = get_file_contents('/resource/negimiku.swf');
    my $d2    = get_file_contents('/resource/saitama-3.bits');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->replace_tag_data(2, \$d2);
    my $got = $swfed->output();
    is ($got, $expect, 'tag001.phpt');
};

tests {
    my $d1    = get_file_path('/resource/negimiku.swf');
    my $d2    = get_file_path('/resource/saitama-3.bits');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->replace_tag_data(2, $d2);
    my $got = $swfed->output();
    is ($got, $expect, 'tag001.phpt');
};

done_testing();
