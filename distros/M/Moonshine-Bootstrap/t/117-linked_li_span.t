use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::LinkedLiSpan;
use Moonshine::Bootstrap::v3::LinkedLiSpan;

moon_test(
    name => 'linked_li_span',
    build => {
        class => 'Moonshine::Bootstrap::Component::LinkedLiSpan',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'linked_li_span',
            args => {
                link => { href => 'http://some.url' },
                span => { data => 'Achoooo' },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li><a href="http://some.url"><span>Achoooo</span></a></li>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'linked_li_span v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::LinkedLiSpan',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'linked_li_span',
            args => {
                link => { href => 'http://some.url' },
                span => { data => 'Achoooo' },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li><a href="http://some.url"><span>Achoooo</span></a></li>'
                }
            ],
        },
    ],
);

sunrise();

1;
