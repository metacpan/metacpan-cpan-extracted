#! perl
use Moonshine::Test qw/:all/;

use Moonshine::Element;

my $cite = Moonshine::Element->new( { tag => 'code', data => '&lt;section&gt;' } );

moon_test(
    name => 'cite',
    build => {
        class => 'Moonshine::Element',
        args  => {
            tag  => 'div',
            data => [ 'hello', $cite, 'should be wrapped as inline' ],
        }
    },
    instructions => [
        {
            test => 'render',
            expected =>
'<div>hello <code>&lt;section&gt;</code> should be wrapped as inline</div>'
        },
    ],
);

moon_test(
    name => 'section',
    build => {
        class => 'Moonshine::Element',
        args  => {
            tag  => 'div',
            data => [ 'hello', { tag => 'code', data => '&lt;section&gt;' }, 'should be wrapped as inline' ],
        }
    },
    instructions => [
        {
            test => 'render',
            expected =>
'<div>hello <code>&lt;section&gt;</code> should be wrapped as inline</div>'
        },
    ],
);

sunrise(4, do_you_lift_bro);

1;
