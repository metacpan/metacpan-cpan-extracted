use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Pager;
use Moonshine::Bootstrap::v3::Pager;

moon_test(
    name => 'pager',
    build => {
        class => 'Moonshine::Bootstrap::Component::Pager',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'pager',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => 
'<ul class="pager"><li><a href="#"><span>Previous</span></a></li><li><a href="#"><span>Next</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pager',
            expected => 'Moonshine::Element',
            args   => { aligned => 1 },
            subtest => [
                {
                    test => 'render',
                    expected => 
'<ul class="pager"><li class="previous"><a href="#"><span>Previous</span></a></li><li class="next"><a href="#"><span>Next</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pager',
            args   => { aligned => 1, disable => 'both' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => 
'<ul class="pager"><li class="previous disabled"><a href="#"><span>Previous</span></a></li><li class="next disabled"><a href="#"><span>Next</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pager',
            args   => { aligned => 1, disable => 'both', nav => 1 },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => 
'<nav><ul class="pager"><li class="previous disabled"><a href="#"><span>Previous</span></a></li><li class="next disabled"><a href="#"><span>Next</span></a></li></ul></nav>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'pager',
    build => {
        class => 'Moonshine::Bootstrap::v3::Pager',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'pager',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => 
'<ul class="pager"><li><a href="#"><span>Previous</span></a></li><li><a href="#"><span>Next</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pager',
            expected => 'Moonshine::Element',
            args   => { aligned => 1 },
            subtest => [
                {
                    test => 'render',
                    expected => 
'<ul class="pager"><li class="previous"><a href="#"><span>Previous</span></a></li><li class="next"><a href="#"><span>Next</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pager',
            args   => { aligned => 1, disable => 'both' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => 
'<ul class="pager"><li class="previous disabled"><a href="#"><span>Previous</span></a></li><li class="next disabled"><a href="#"><span>Next</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pager',
            args   => { aligned => 1, disable => 'both', nav => 1 },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => 
'<nav><ul class="pager"><li class="previous disabled"><a href="#"><span>Previous</span></a></li><li class="next disabled"><a href="#"><span>Next</span></a></li></ul></nav>'
                }
            ],
        },
    ],
);

sunrise();
