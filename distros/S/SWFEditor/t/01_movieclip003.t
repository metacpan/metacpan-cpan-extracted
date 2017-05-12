use t::Utils;
use Test::More;
use SWFEditor;

note('replace_movie_clip instancename search from nested symbol');

my $expect = get_file_contents('/swf/movieclip003.swf');

tests {
    my $d1    = get_file_contents('/resource/negimiku2_mcnest.swf');
    my $d2    = get_file_contents('/resource/saitama3.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->replace_movie_clip('miku/negi', \$d2);
    my $got = $swfed->output();
    is ($got, $expect, 'movieclip003.phpt');
};

tests {
    my $d1    = get_file_path('/resource/negimiku2_mcnest.swf');
    my $d2    = get_file_path('/resource/saitama3.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->replace_movie_clip('miku/negi', $d2);
    my $got = $swfed->output();
    is ($got, $expect, 'movieclip003.phpt');
};

done_testing();
