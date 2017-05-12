use Moonshine::Test qw/:all/;
use strict;
use warnings;
use Moonshine::Bootstrap::Component::InputGroupAddon;
use Moonshine::Bootstrap::v3::InputGroupAddon;

my $instance = Moonshine::Bootstrap::Component::InputGroupAddon->new;

moon_test(
    name         => 'input',
    instance     => $instance,
    instructions => [
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                data => q(@),
                id   => 'basic-addon1',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<span class="input-group-addon" id="basic-addon1">@</span>',
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                checkbox => 1,
                id       => 'basic-addon1',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<span class="input-group-addon" id="basic-addon1"><input class="form-control" type="checkbox"></input></span>',
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                radio => 1,
                id    => 'basic-addon1',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<span class="input-group-addon" id="basic-addon1"><input class="form-control" type="radio"></input></span>',
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                id     => 'basic-addon1',
                button => {
                    data => 'Go!',
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<span class="input-group-btn" id="basic-addon1"><button class="btn btn-default" type="button">Go!</button></span>',
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                id       => 'basic-addon1',
                dropdown => {
                    mid => 'dropdownMenu1',
                    ul  => {
                        children => [
                            {
                                action => 'linked_li',
                                link   => 'http://some.url',
                                data   => 'URL',
                            },
                            {
                                action => 'linked_li',
                                link   => 'http://second.url',
                                data   => 'Second',
                            }
                        ],
                    },
                    button => {
                        id   => 'dropdownMenu1',
                        data => 'Dropdown',
                    },
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group-btn" id="basic-addon1"><button class="dropdown-toggle btn btn-default" id="dropdownMenu1" type="button" aria-expanded="true" aria-haspopup="true" data-toggle="dropdown">Dropdown<span class="caret"></span></button><ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul></div>'
                }
            ],
        },
    ]
);

my $v3Instance = Moonshine::Bootstrap::v3::InputGroupAddon->new;

moon_test(
    name         => 'Input - v3',
    instance     => $v3Instance,
    instructions => [
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                data => q(@),
                id   => 'basic-addon1',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<span class="input-group-addon" id="basic-addon1">@</span>',
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                checkbox => 1,
                id       => 'basic-addon1',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<span class="input-group-addon" id="basic-addon1"><input class="form-control" type="checkbox"></input></span>',
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                radio => 1,
                id    => 'basic-addon1',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<span class="input-group-addon" id="basic-addon1"><input class="form-control" type="radio"></input></span>',
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                id     => 'basic-addon1',
                button => {
                    data => 'Go!',
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<span class="input-group-btn" id="basic-addon1"><button class="btn btn-default" type="button">Go!</button></span>',
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'input_group_addon',
            expected => 'Moonshine::Element',
            args     => {
                id       => 'basic-addon1',
                dropdown => {
                    mid => 'dropdownMenu1',
                    ul  => {
                        children => [
                            {
                                action => 'linked_li',
                                link   => 'http://some.url',
                                data   => 'URL',
                            },
                            {
                                action => 'linked_li',
                                link   => 'http://second.url',
                                data   => 'Second',
                            }
                        ],
                    },
                    button => {
                        id   => 'dropdownMenu1',
                        data => 'Dropdown',
                    },
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group-btn" id="basic-addon1"><button class="dropdown-toggle btn btn-default" id="dropdownMenu1" type="button" aria-expanded="true" aria-haspopup="true" data-toggle="dropdown">Dropdown<span class="caret"></span></button><ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul></div>'
                }
            ],
        },
    ]
);






sunrise();
