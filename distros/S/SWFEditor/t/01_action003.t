use t::Utils;
use Test::More;
use SWFEditor;

note('set_action_variables() : merge to doaction (no 0 terminate record)');

my $expect = get_file_contents('/swf/action003.swf');

tests {
    my $d1    = get_file_contents('/resource/textvar-no0.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    $swfed->set_action_variables({
        dummy => 'dummydummy',
    });
    my $got = $swfed->output();
    is ($got, $expect, 'action003.phpt');
};

tests {
    my $d1    = get_file_path('/resource/textvar-no0.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    $swfed->set_action_variables({
        dummy => 'dummydummy',
    });
    my $got = $swfed->output();
    is ($got, $expect, 'action003.phpt');
};

done_testing();
