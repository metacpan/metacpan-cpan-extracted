use t::Utils;
use Test::More;
use SWFEditor;

note('replaceMovieClip with font specify');

my $expect = get_file_contents('/swf/movieclip005.swf');

tests {
    my $d1    = get_file_contents('/resource/font_test.swf');
    my $d2    = get_file_contents('/resource/font_test_material.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->replace_movie_clip('a', \$d2);
    $swfed->purge_useless_contents();
    my $got = $swfed->output();
    is ($got, $expect, 'movieclip005.phpt');
};

tests {
    my $d1    = get_file_path('/resource/font_test.swf');
    my $d2    = get_file_path('/resource/font_test_material.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->replace_movie_clip('a', $d2);
    $swfed->purge_useless_contents();
    my $got = $swfed->output();
    is ($got, $expect, 'movieclip004.phpt');
};

done_testing();
