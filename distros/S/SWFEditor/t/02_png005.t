use t::Utils;
use Test::More;
use SWFEditor;
use FindBin;

note('replace_png_data(): with opt');

my $expect = get_file_contents('/swf/png005.swf');

tests {
    my $d1    = get_file_contents('/resource/saitama.swf');
    my $d2    = get_file_contents('/resource/negimiku001.png24');
    my $swfed = SWFEditor->new();
    $swfed->set_shape_adjust_mode_type_tilled();
    $swfed->input(\$d1);
    my $image_id = 1;
    $swfed->replace_png_data($image_id, \$d2, { rgb15 => 1 });
    my $got = $swfed->output();
    is ($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/saitama.swf');
    my $d2    = get_file_path('/resource/negimiku001.png24');
    my $swfed = SWFEditor->new();
    $swfed->set_shape_adjust_mode_type_tilled();
    $swfed->input($d1);
    my $image_id = 1;
    $swfed->replace_png_data($image_id, $d2, { rgb15 => 1 });
    my $got = $swfed->output();
    is ($got, $expect, '');
};

done_testing();
