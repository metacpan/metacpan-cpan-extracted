use t::Utils;
use Test::More;
use SWFEditor;

note('get_tag_list(): test');

my $expect = [
    {
        code    => 9,
        tag     => 9,
        tagName => 'SetBackgroundColor',
        length  => 3,
    },
    {
        code    => 12,
        tag     => 12,
        tagName => 'DoAction',
        length  => 28,
        detail  => 1,
    },
    {
        code    => 48,
        tag     => 48,
        tagName => 'DefineFont2',
        length  => 25,
    },
    {
        code    => 37,
        tag     => 37,
        tagName => 'DefineEditText',
        length  => 45,
        detail  => 1,
    },
    {
        code    => 26,
        tag     => 26,
        tagName => 'PlaceObject2',
        length  => 9,
        detail  => 1,
    },
    {
        code    => 1,
        tag     => 1,
        tagName => 'ShowFrame',
        length  => 0,
    },
    {
        code    => 0,
        tag     => 0,
        tagName => 'End',
        length  => 0,
    },
];

tests {
    my $d1    = get_file_contents('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input(\$d1);
    my $got = $swfed->get_tag_list();
    is_deeply($got, $expect, '');
};

tests {
    my $d1    = get_file_path('/resource/textvar.swf');
    my $swfed = SWFEditor->new();
    $swfed->input($d1);
    my $got = $swfed->get_tag_list();
    is_deeply($got, $expect, '');
};

done_testing();
