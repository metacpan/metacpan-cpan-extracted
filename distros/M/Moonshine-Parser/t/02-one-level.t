use Moonshine::Test qw/:all/;

use Moonshine::Parser::HTML;

moon_test(
    name => 'simple',
    build => {
        class => 'Moonshine::Parser::HTML',
    },
    instructions => [
        {
            test => 'obj',
            func => 'parse_file',
            args => [
                't/html/simple.html',
            ],
            args_list => 1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<html><head><title>A HTML standard template</title><meta charset="utf-8"></meta></head><body><table class="two-columns" id="table-1"><tr><th class="month">Description</th><th class="savings">Facts</th></tr><tr class="two-column-odd" id="row-1"><td id="title">Some Description Some Description Some Description Some Description</td><td class="facts"><table><tr><td>Hello</td></tr><tr><td>Goodbye</td></tr></table></td></tr></table></body></html>'
                }
            ]
        }
    ],
);

moon_test(
    name => 'one level',
    build => {
        class => 'Moonshine::Parser::HTML',
    },
    instructions => [
        {
            test => 'obj',
            func => 'parse_file',
            args => [
                't/html/one-level.html',
            ],
            args_list => 1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<html><head><title>A HTML standard template</title><meta charset="utf-8"></meta></head><body><table class="two-columns" id="table-1"><tr><th class="month">Description</th><th class="savings">Facts</th></tr><tr class="two-column-odd" id="row-1"><td id="title">Some Description Some Description Some Description Some Description</td><td class="facts"><table><tr><td>Hello</td></tr><tr><td>Goodbye</td></tr></table></td></tr><tr class="two-column-even" id="row-2"><td id="title">一些說明</td><td class="facts"><table><tr><td>你好</td></tr><tr><td name="findme">再見</td></tr></table></td></tr></table></body></html>'
                },
                {
                    test => 'obj',
                    func => 'findme',
                    expected => 'Moonshine::Element',
                    subtest => [
                        {
                            test => 'render',
                            expected => '<td name="findme">再見</td>',
                        }
                    ]
                }
            ]
        }
    ],
);

moon_test(
    name => 'one level',
    build => {
        class => 'Moonshine::Parser::HTML',
    },
    instructions => [
        {
            test => 'obj',
            func => 'parse_file',
            args => [
                't/html/embedded.html',
            ],
            args_list => 1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<html><head><title>A HTML standard template</title><meta charset="utf-8"></meta></head><body><table class="two-columns" id="table-1"><tr><th class="month">Description</th><th class="savings">Facts</th></tr><tr class="two-column-odd" id="row-1"><td id="title">Some Description Some Description Some Description Some Description</td><td class="facts">This text <small>small text</small> More text</td></tr></table></body></html>',
                },
            ]
        }
    ],
);


sunrise();
