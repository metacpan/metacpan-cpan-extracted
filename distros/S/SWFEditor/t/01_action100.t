use t::Utils;
use Test::More;
use SWFEditor;

note('replace_action_string() : ActionPush longer parameter');

my $expect = get_file_contents('/swf/action100.swf');

tests {
    my $d1    = get_file_contents('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->replace_action_strings({
        dummy    => 'dummydummy',
        inputvar => 'replacedvar',
    });
    my $got = $swfed->output();
    is ($got, $expect, 'action100.phpt');
};

tests {
    my $d1    = get_file_path('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->replace_action_strings({
        dummy    => 'dummydummy',
        inputvar => 'replacedvar',
    });
    my $got = $swfed->output();
    is ($got, $expect, 'action100.phpt');
};

done_testing();
