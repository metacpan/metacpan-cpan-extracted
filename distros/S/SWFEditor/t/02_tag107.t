use t::Utils;
use Test::More;
use SWFEditor;

note('remove_tag(): test');

my $expect = get_file_contents('/swf/tag107.swf');

tests {
    my $d1    = get_file_contents('/resource/saitama3.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->remove_tag(1);
    my $got = $swfed->output();
    is_deeply($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/saitama3.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->remove_tag(1);
    my $got = $swfed->output();
    is_deeply($got, $expect, '');
};

done_testing();
