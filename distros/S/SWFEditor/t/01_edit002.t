use t::Utils;
use Test::More;
use SWFEditor;

note('replace_edit_string() test');

tests {
    my $d1    = get_file_contents('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $got1 = $swfed->get_edit_string('textvar');
    my $got2 = $swfed->get_edit_string('text');
    my $got3 = $swfed->get_edit_string('');
    is ($got1, 'ABCDEFG', 'edit002.phpt');
    is ($got2, undef,     'edit002.phpt');
    is ($got3, undef,     'edit002.phpt');
};

tests {
    my $d1    = get_file_path('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $got1 = $swfed->get_edit_string('textvar');
    my $got2 = $swfed->get_edit_string('text');
    my $got3 = $swfed->get_edit_string('');
    is ($got1, 'ABCDEFG', 'edit002.phpt');
    is ($got2, undef,     'edit002.phpt');
    is ($got3, undef,     'edit002.phpt');
};

done_testing();
