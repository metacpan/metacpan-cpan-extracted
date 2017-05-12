use t::Utils;
use Test::More;
use SWFEditor;

note('get_action_data(): test');

my $expect = get_file_contents('/action/textvar.action.1');

tests {
    my $d1    = get_file_contents('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $got = $swfed->get_action_data(1);
    is ($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $got = $swfed->get_action_data(1);
    is ($got, $expect, '');
};

done_testing();
