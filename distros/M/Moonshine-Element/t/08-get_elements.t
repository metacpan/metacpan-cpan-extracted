use Moonshine::Test qw/:all/;
use Moonshine::Element;

my $element = Moonshine::Element->new(
    {
        tag => 'div',
        children => [
            {
                tag => 'p',
                id => 'findme',
                data => [ 'Hey', 'You' ],
            }
        ] 
    }
);

moon_test(
    name => 'get_element_by_id - first child - easy - ' . kirby,
    instance => $element,
    instructions => [
        {
            test => 'render',
            expected => '<div><p id="findme">Hey You</p></div>',
        },
        {
            test => 'ref_index_obj',
            index => 0,
            func => 'get_elements',
            args => [ 'findme', ['id'] ],
            args_list => 1,
            expected => 'Moonshine::Element',
        }
    ]
);

my $elements = $element->get_elements('findme', ['id']);
render_me(
    instance => $elements->[0],
    expected => '<p id="findme">Hey You</p>',
);

my $element_comp = Moonshine::Element->new(
    {
        tag => 'div',
        after_element => [
            {
                tag => 'p',
                id => 'hiding',
                data => [ 'One', 'Two' ],
                children => [
                    {
                        tag => 'span',
                        class => { 1 => 'found' },
                        data => [ 'If', 'You', 'Can' ],
                    },
                ]
            },
        ],
        children => [
            {
                tag => 'p',
                id => 'findme',
                class => [ 'found' ],
                data => [ 'Catch', 'Me' ],
            }
        ],
        before_element => [
            {
                tag => 'p',
                id => 'hiding',
                data => [ 'One', 'Two' ],
                children => [
                    {
                        tag => 'span',
                        class => 'okay found',
                        data => [ 'Hey', 'You' ],
                    },
                ]
             },             
        ], 
    }
);

moon_test(
    name => 'get_element_by_id - before - children - after ',
    instance => $element_comp,
    instructions => [
        {
            test => 'render',
            expected => '<p id="hiding">One Two<span class="okay found">Hey You</span></p><div><p class="found" id="findme">Catch Me</p></div><p id="hiding">One Two<span class="found">If You Can</span></p>',
        },
        {
            test => 'count_ref',
            func => 'get_elements',
            args => [ 'found', ['class'] ],
            args_list => 1,
            expected => 3,
        },
        {
            test => 'count_ref',
            func => 'get_elements_by_class',
            args => [ 'found' ],
            args_list => 1,
            expected => 3,
        },
        {
            test => 'count_ref',
            func => 'get_elements_by_class',
            args => [ 'okay found' ],
            args_list => 1,
            expected => 1,
        },
        {
            catch => 1,
            func => 'get_elements_by_class',
            expected => qr/first param passed to get_elements_by_class not a scalar/,
        },
        {
            test => 'count_ref',
            func => 'get_elements_by_tag',
            args => [ 'span' ],
            args_list => 1,
            expected => 2,
        },
        {
            catch => 1,
            func => 'get_elements_by_tag',
            expected => qr/first param passed to get_elements_by_tag not a scalar/,
        },
    ]
);

my $findme = $element_comp->get_elements('findme', ['id']);
render_me(
    instance => $findme->[0],
    expected => '<p class="found" id="findme">Catch Me</p>',
);

my $found_get_elements = $element_comp->get_elements('found', ['class']);
my $found_get_elements_by_class = $element_comp->get_elements_by_class('found');

for my $found ( ($found_get_elements, $found_get_elements_by_class ) ) {
    render_me(
        instance => $found->[0],
        expected => '<span class="okay found">Hey You</span>',
    );
    render_me(
        instance => $found->[1],
        expected => '<p class="found" id="findme">Catch Me</p>',
    );
    render_me(
        instance => $found->[2],
        expected => '<span class="found">If You Can</span>',
    );
}

sunrise(19, strut);
