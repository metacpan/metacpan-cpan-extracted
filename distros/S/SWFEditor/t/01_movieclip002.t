use t::Utils;
use Test::More;
use SWFEditor;

note('replace_movie_clip and purge');

my $expect = get_file_contents('/swf/movieclip002.swf');

tests {
    my $d1    = get_file_contents('/resource/negimiku.swf');
    my $d2    = get_file_contents('/resource/saitama3.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->replace_movie_clip('miku', \$d2);
    $swfed->purge_useless_contents();
    my $got = $swfed->output();
    is ($got, $expect, 'movieclip002.phpt');
};

tests {
    my $d1    = get_file_path('/resource/negimiku.swf');
    my $d2    = get_file_path('/resource/saitama3.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->replace_movie_clip('miku', $d2);
    $swfed->purge_useless_contents();
    my $got = $swfed->output();
    is ($got, $expect, 'movieclip002.phpt');
};

done_testing();
