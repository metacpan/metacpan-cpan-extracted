use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Pagination;
use Moonshine::Bootstrap::v3::Pagination;

moon_test(
    name => 'pagination',
    build => {
        class => 'Moonshine::Bootstrap::Component::Pagination',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'pagination',
            args   => { count => 5 },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="pagination"><li><a href="#" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li><li><a href="#">1</a></li><li><a href="#">2</a></li><li><a href="#">3</a></li><li><a href="#">4</a></li><li><a href="#">5</a></li><li><a href="#" aria-label="Next"><span aria-hidden="true">&raquo;</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pagination',
            args   => { count  => 5, sizing => 'lg' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="pagination pagination-lg"><li><a href="#" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li><li><a href="#">1</a></li><li><a href="#">2</a></li><li><a href="#">3</a></li><li><a href="#">4</a></li><li><a href="#">5</a></li><li><a href="#" aria-label="Next"><span aria-hidden="true">&raquo;</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pagination',
            args   => { nav => 1, count  => 5, sizing => 'lg' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => 
'<nav><ul class="pagination pagination-lg"><li><a href="#" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li><li><a href="#">1</a></li><li><a href="#">2</a></li><li><a href="#">3</a></li><li><a href="#">4</a></li><li><a href="#">5</a></li><li><a href="#" aria-label="Next"><span aria-hidden="true">&raquo;</span></a></li></ul></nav>'
                }
            ],
        },

    ],
);

moon_test(
    name => 'pagination',
    build => {
        class => 'Moonshine::Bootstrap::v3::Pagination',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'pagination',
            args   => { count => 5 },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="pagination"><li><a href="#" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li><li><a href="#">1</a></li><li><a href="#">2</a></li><li><a href="#">3</a></li><li><a href="#">4</a></li><li><a href="#">5</a></li><li><a href="#" aria-label="Next"><span aria-hidden="true">&raquo;</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pagination',
            args   => { count  => 5, sizing => 'lg' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="pagination pagination-lg"><li><a href="#" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li><li><a href="#">1</a></li><li><a href="#">2</a></li><li><a href="#">3</a></li><li><a href="#">4</a></li><li><a href="#">5</a></li><li><a href="#" aria-label="Next"><span aria-hidden="true">&raquo;</span></a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'pagination',
            args   => { nav => 1, count  => 5, sizing => 'lg' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => 
'<nav><ul class="pagination pagination-lg"><li><a href="#" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li><li><a href="#">1</a></li><li><a href="#">2</a></li><li><a href="#">3</a></li><li><a href="#">4</a></li><li><a href="#">5</a></li><li><a href="#" aria-label="Next"><span aria-hidden="true">&raquo;</span></a></li></ul></nav>'
                }
            ],
        },

    ],
);


sunrise();
