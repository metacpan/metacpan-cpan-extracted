use t::Utils;
use Test::More;
use SWFEditor;

note('set_action_variables() : create doaction');

my $expect = get_file_contents('/swf/action002.swf');

tests {
    my $d1    = get_file_contents('/resource/textvar-noaction.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->set_action_variables({
        testvar => 'dummydummy',
    });
    my $got = $swfed->output();
    is ($got, $expect, 'action002.phpt');
};

tests {
    my $d1    = get_file_path('/resource/textvar-noaction.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->set_action_variables({
        testvar => 'dummydummy',
    });
    my $got = $swfed->output();
    is ($got, $expect, 'action002.phpt');
};

done_testing();
