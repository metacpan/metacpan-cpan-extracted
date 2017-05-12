use t::Utils;
use Test::More;
use SWFEditor;

note('replace_edit_string() test');

my $expect = get_file_contents('/swf/edit001.swf');

tests {
    my $d1    = get_file_contents('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->replace_edit_string('textvar', 'hello world');
    my $got = $swfed->output();
    is ($got, $expect, 'edit001.phpt');
};

tests {
    my $d1    = get_file_path('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->replace_edit_string('textvar', 'hello world');
    my $got = $swfed->output();
    is ($got, $expect, 'edit001.phpt');
};

done_testing();
