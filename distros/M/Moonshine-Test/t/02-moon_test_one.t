use Test::Tester;

use Moonshine::Test qw/:all/;
use Test::MockObject;

(my $element = Test::MockObject->new)
    ->set_isa('Moonshine::Element');

$element->mock('render', sub { 
    my $args = $_[1]; 
    my $tag = delete $args->{tag};  
    my $text = delete $args->{data} // '';
    my $attributes = '';
    map {$attributes .= ' ';$attributes .= sprintf( '%s="%s"', $_, $args->{$_} );} keys %{ $args };
    return sprintf('<%s%s>%s</%s>', $tag, $attributes, $text, $tag);
}); 

(my $instance = Test::MockObject->new)->set_isa('Moonshine::Component');

$instance->mock('p', sub { my $args = $_[1]; 
    return (Test::MockObject->new)->mock('render', sub { $element->render({tag => 'p', %{$args} }) }) 
});

(my $div = Test::MockObject->new)->set_isa('Moonshine::Element');
$div->mock('render', sub { $element->render({tag => 'div', class => 'test', data => 'test' }) }); 

$instance->mock('broken', sub { my $args = $_[1]; 
    return (Test::MockObject->new)->mock('render', sub { $element->render({%{$args}}) }) 
});

check_test(
    sub {
        moon_test_one(
            test => 'render',
            instance => $instance,
            func => 'p',
            args => {
                data => 'test',
            },
            expected => '<p>test</p>'
        );
    },
    {
        ok => 1,
        name => "render instance: <p>test</p>",
        depth => 3,
        completed => 1,
    },
    'test render_me(p)'
);

my $arrayref = [ { name => 'one' }, { name => 'two' } ];
$instance->mock('arrayref', sub { return $arrayref });

check_test(
    sub {
        moon_test_one(
            test => 'ref',
            instance => $instance,
            func => 'arrayref',
            expected => $arrayref,
        );
    },
    {
        ok => 1,
        name => "function: arrayref is ref - is_deeply",
        depth => 2,
        completed => 1,
    },
    'test mocked arrayref'
);

my $hashref = { name => 'one', second => 'two' };
$instance->mock('hashref', sub { return $hashref });

check_test(
    sub {
        moon_test_one(
            test => 'ref',
            instance => $instance,
            func => 'hashref',
            expected => $hashref,
        );
    },
    {
        ok => 1,
        name => "function: hashref is ref - is_deeply",
        depth => 2,
        completed => 1,
    },
    'test mocked hashref'
);

my @array = (qw/one two three/);
$instance->mock('array', sub { return @array });

check_test(
    sub {
        moon_test_one(
            test => 'array',
            instance => $instance,
            func => 'array',
            expected => [qw/one two three/],
        );
    },
    {
        ok => 1,
        name => "function: array is array - reference - is_deeply",
        depth => 2,
        completed => 1,
    },
    'test mocked array'
);

my %hash = (map { $_ => 1 } qw/one two three/);
$instance->mock('hash', sub { return %hash });

check_test(
    sub {
        moon_test_one(
            test => 'hash',
            instance => $instance,
            func => 'hash',
            expected => \%hash,
        );
    },
    {
        ok => 1,
        name => "function: hash is hash - reference - is_deeply",
        depth => 2,
        completed => 1,
    },
    'test mocked hash'
);

$instance->mock('obj', sub { return bless {}, 'Test::Moon'; });

check_test(
    sub {
        moon_test_one(
            test => 'obj',
            instance => $instance,
            func => 'obj',
            expected => 'Test::Moon',
        );
    },
    {
        ok => 1,
        name => "'function: obj is Object - blessed - is - Test::Moon' isa 'Test::Moon'",
        depth => 2,
        completed => 1,
    },
    'test mocked obj'
);

$instance->mock('catch', sub { die 'a horrible death'; });

check_test(
    sub {
        moon_test_one(
            catch => 1,
            instance => $instance,
            func => 'catch',
            expected => 'a horrible death',
        );
    },
    {
        ok => 1,
        name => "catch is like - a horrible death",
        depth => 2,
        completed => 1,
    },
    'test mocked catch(die)'
);

check_test(
    sub {
        moon_test_one(
            test => 'render',
            instance => $instance,
            func => 'broken',
            args => {
                class => 'test',
                data  => 'test',
            },
            expected => '<div class="test">test</div>'
        );
    },
    {
        ok => 0,
        name => "render instance: <div class=\"test\">test</div>",
        depth => 3,
        diag => "         got: '< class=\"test\">test</>'\n    expected: '<div class=\"test\">test</div>'"
    },
    'test broken()'
);

check_test(
    sub {
        moon_test_one(
            instance => $instance,
            func => 'hash',
            expected => \%hash,
        );
    },
    {
        ok => 0,
        diag => "No instruction{test} passed to moon_test_one",
        depth => 2,
    },
    'test no instruction'
);


$instance->mock('true', sub { return 1; });

check_test(
    sub {
        moon_test_one(
            test => 'true',
            instance => $instance,
            func => 'true',
        );
    },
    {
        ok => 1,
        name => "function: true is true - 1",
        depth => 2,
        completed => 1,
    },
    'test mocked true'
);

$instance->mock('false', sub { return 0; });

check_test(
    sub {
        moon_test_one(
            test => 'false',
            instance => $instance,
            func => 'false',
        );
    },
    {
        ok => 1,
        name => "function: false is false - 0",
        depth => 2,
        completed => 1,
    },
    'test mocked false'
);

$instance->mock('undefined', sub { return undef; });

check_test(
    sub {
        moon_test_one(
            test => 'undef',
            instance => $instance,
            func => 'undefined',
        );
    },
    {
        ok => 1,
        name => "function: undefined is undef",
        depth => 2,
        completed => 1,
    },
    'test mocked undef'
);

$instance->mock('ref_scalar_key', sub { return { thing => 1234 }; });

check_test(
    sub {
        moon_test_one(
            test => 'ref_key_scalar',
            instance => $instance,
            func => 'ref_scalar_key',
            key => 'thing',
            expected => 1234,
        );
    },
    {
        ok => 1,
        name => "function: ref_scalar_key is ref - has scalar key: thing - is - 1234",
        depth => 2,
        completed => 1,
    },
    'test ref_key_scalar'
);

check_test(
    sub {
        moon_test_one(
            test => 'ref_key_scalar',
            instance => $instance,
            func => 'ref_scalar_key',
            expected => 1234,
        );
    },
    {
        ok => 0,
        name => "No key passed to test - ref_key_scalar - testing - function: ref_scalar_key",
        depth => 2,
        completed => 1,
    },
    'test mocked ref_scalar_key no key '
);

$instance->mock('ref_ref_key', sub { return { thing => { okay => 'yes' } }; });

check_test(
    sub {
        moon_test_one(
            test => 'ref_key_ref',
            instance => $instance,
            func => 'ref_ref_key',
            key => 'thing',
            expected => { okay => 'yes' },
        );
    },
    {
        ok => 1,
        name => "function: ref_ref_key is ref - has ref key: thing - is_deeply - ref",
        depth => 2,
        completed => 1,
    },
    'test ref_key_ref'
);

$instance->mock('ref_refa_key', sub { return { thing => [ 'okay', 'yes' ] }; });

check_test(
    sub {
        moon_test_one(
            test => 'ref_key_ref',
            instance => $instance,
            func => 'ref_refa_key',
            key => 'thing',
            expected => [ 'okay', 'yes' ],
        );
    },
    {
        ok => 1,
        name => "function: ref_refa_key is ref - has ref key: thing - is_deeply - ref",
        depth => 2,
        completed => 1,
    },
    'test ref_key_ref'
);

check_test(
    sub {
        moon_test_one(
            test => 'ref_key_ref',
            instance => $instance,
            func => 'ref_ref_key',
            expected => { okay => 'yes' },
        );
    },
    {
        ok => 0,
        name => "No key passed to test - ref_key_ref - testing - function: ref_ref_key",
        depth => 2,
        completed => 1,
    },
    'test mocked ref_key_ref no key'
);

$instance->mock('ref_index', sub { return [ 'thing', { thing => 'okay' }, 'yes' ] });

check_test(
    sub {
        moon_test_one(
            test => 'ref_index_scalar',
            instance => $instance,
            func => 'ref_index',
            index => 0,
            expected => 'thing',
        );
    },
    {
        ok => 1,
        name => "function: ref_index is ref - has scalar index: 0 - is - thing",
        depth => 2,
        completed => 1,
    },
    'test ref_index_scalar'
);

check_test(
    sub {
        moon_test_one(
            test => 'ref_index_scalar',
            instance => $instance,
            func => 'ref_index',
            expected => 'thing',
        );
    },
    {
        ok => 0,
        name => "No index passed to test - ref_index_scalar - testing - function: ref_index",
        depth => 2,
        completed => 1,
    },
    'test mocked ref_index_scalar no key'
);

check_test(
    sub {
        moon_test_one(
            test => 'ref_index_ref',
            instance => $instance,
            func => 'ref_index',
            index => 1,
            expected => { thing => 'okay' },
        );
    },
    {
        ok => 1,
        name => "function: ref_index is ref - has ref index: 1 - is_deeply - ref",
        depth => 2,
        completed => 1,
    },
    'test ref_index_ref'
);

check_test(
    sub {
        moon_test_one(
            test => 'ref_index_ref',
            instance => $instance,
            func => 'ref_index',
            expected => 'thing',
        );
    },
    {
        ok => 0,
        name => "No index passed to test - ref_index_ref - testing - function: ref_index",
        depth => 2,
        completed => 1,
    },
    'test mocked ref_index_ref no index'
);


$instance->mock('ref_like_key', sub { return { exception => 'mehhh the world has ended line 123 some_method.' }; });

check_test(
    sub {
        moon_test_one(
            test => 'ref_key_like',
            instance => $instance,
            func => 'ref_like_key',
            key => 'exception',
            expected => 'mehhh the world has ended',
        );
    },
    {
        ok => 1,
        name => "function: ref_like_key is ref - has scalar key: exception - like - mehhh the world has ended",
        depth => 2,
        completed => 1,
    },
    'test ref_key_like'
);

check_test(
    sub {
        moon_test_one(
            test => 'ref_key_like',
            instance => $instance,
            func => 'ref_like_key',
            expected => 1234,
        );
    },
    {
        ok => 0,
        name => "No key passed to test - ref_key_like - testing - function: ref_like_key",
        depth => 2,
        completed => 1,
    },
    'test mocked ref_key_like no key'
);

$instance->mock('ref_like_ref', sub { return [ 'exception', 'mehhh the world has ended line 123 some_method.' ] });

check_test(
    sub {
        moon_test_one(
            test => 'ref_index_like',
            instance => $instance,
            func => 'ref_like_ref',
            index => 1,
            expected => 'mehhh the world has ended',
        );
    },
    {
        ok => 1,
        name => "function: ref_like_ref is ref - has scalar index: 1 - like - mehhh the world has ended",
        depth => 2,
        completed => 1,
    },
    'test ref_index_like'
);

check_test(
    sub {
        moon_test_one(
            test => 'ref_index_like',
            instance => $instance,
            func => 'ref_like_key',
            expected => 1234,
        );
    },
    {
        ok => 0,
        name => "No index passed to test - ref_index_like - testing - function: ref_like_key",
        depth => 2,
        completed => 1,
    },
    'test mocked ref_key_like no key'
);

$instance->mock('list_like_ref', sub { return ( 'exception', 'mehhh the world has ended line 123 some_method.' ) });

check_test(
    sub {
        moon_test_one(
            test => 'list_index_like',
            instance => $instance,
            func => 'list_like_ref',
            index => 1,
            expected => 'mehhh the world has ended',
        );
    },
    {
        ok => 1,
        name => "function: list_like_ref is list - has scalar index: 1 - like - mehhh the world has ended",
        depth => 2,
        completed => 1,
    },
    'test list_index_like'
);

check_test(
    sub {
        moon_test_one(
            test => 'list_index_like',
            instance => $instance,
            func => 'list_like_ref',
            expected => 1234,
        );
    },
    {
        ok => 0,
        name => "No index passed to test - list_index_like - testing - function: list_like_ref",
        depth => 2,
        completed => 1,
    },
    'test mocked list_index_like no key'
);

$instance->mock('list_index', sub { return ( 'thing', { thing => 'okay' }, 'yes' ) });

check_test(
    sub {
        moon_test_one(
            test => 'list_index_scalar',
            instance => $instance,
            func => 'list_index',
            index => 0,
            expected => 'thing',
        );
    },
    {
        ok => 1,
        name => "function: list_index is list - has scalar index: 0 - is - thing",
        depth => 2,
        completed => 1,
    },
    'test list_index_scalar'
);

check_test(
    sub {
        moon_test_one(
            test => 'list_index_scalar',
            instance => $instance,
            func => 'list_index',
            expected => 'thing',
        );
    },
    {
        ok => 0,
        name => "No index passed to test - list_index_scalar - testing - function: list_index",
        depth => 2,
        completed => 1,
    },
    'test mocked list_index_scalar no key'
);

check_test(
    sub {
        moon_test_one(
            test => 'list_index_ref',
            instance => $instance,
            func => 'list_index',
            index => 1,
            expected => { thing => 'okay' },
        );
    },
    {
        ok => 1,
        name => "function: list_index is list - has ref index: 1 - is_deeply - ref",
        depth => 2,
        completed => 1,
    },
    'test list_index_ref'
);

check_test(
    sub {
        moon_test_one(
            test => 'list_index_ref',
            instance => $instance,
            func => 'list_index',
            expected => 'thing',
        );
    },
    {
        ok => 0,
        name => "No index passed to test - list_index_ref - testing - function: list_index",
        depth => 2,
        completed => 1,
    },
    'test mocked list_index_ref no index'
);

$instance->mock('list_key', sub { return ( 'thing' => { thing => 'okay' }, 'yes' => 'okay something slow' ) });

check_test(
    sub {
        moon_test_one(
            test => 'list_key_scalar',
            instance => $instance,
            func => 'list_key',
            key => 'yes',
            expected => 'okay something slow',
        );
    },
    {
        ok => 1,
        name => "function: list_key is list - has scalar key: yes - is - okay something slow",
        depth => 2,
        completed => 1,
    },
    'test list_key_scalar'
);

check_test(
    sub {
        moon_test_one(
            test => 'list_key_scalar',
            instance => $instance,
            func => 'list_key',
            expected => 'thing',
        );
    },
    {
        ok => 0,
        name => "No key passed to test - list_key_scalar - testing - function: list_key",
        depth => 2,
        completed => 1,
    },
    'test mocked list_key_scalar no key'
);

check_test(
    sub {
        moon_test_one(
            test => 'list_key_ref',
            instance => $instance,
            func => 'list_key',
            key => 'thing',
            expected => { thing => 'okay' },
        );
    },
    {
        ok => 1,
        name => "function: list_key is list - has ref key: thing - is_deeply - ref",
        depth => 2,
        completed => 1,
    },
    'test list_key_ref'
);

check_test(
    sub {
        moon_test_one(
            test => 'list_key_ref',
            instance => $instance,
            func => 'list_key',
            expected => { okay => 'thing' },
        );
    },
    {
        ok => 0,
        name => "No key passed to test - list_key_ref - testing - function: list_key",
        depth => 2,
        completed => 1,
    },
    'test mocked list_key_ref no key'
);

check_test(
    sub {
        moon_test_one(
            test => 'list_key_like',
            instance => $instance,
            func => 'list_key',
            key => 'yes',
            expected => 'something',
        );
    },
    {
        ok => 1,
        name => "function: list_key is list - has scalar key: yes - like - something",
        depth => 2,
        completed => 1,
    },
    'test list_key_like'
);

check_test(
    sub {
        moon_test_one(
            test => 'list_key_like',
            instance => $instance,
            func => 'list_key',
            expected => 1234,
        );
    },
    {
        ok => 0,
        name => "No key passed to test - list_key_like - testing - function: list_key",
        depth => 2,
        completed => 1,
    },
    'test mocked list_key_like no key'
);

check_test(
    sub {
        moon_test_one(
            test => 'ok',
            instance => $instance,
            func => 'list_key',
        );
    },
    {
        ok => 1,
        name => "function: list_key is ok",
        depth => 2,
        completed => 1,
    },
    'test mocked ok'
);

check_test(
    sub {
        moon_test_one(
            test => 'skip',
            instance => $instance,
            func => 'list_key',
        );
    },
    {
        ok => 1,
        name => "function: list_key - skip",
        depth => 2,
        completed => 1,
    },
    'test mocked skip'
);


$instance->mock('ref_ind_obj', sub { return [ (bless {}, 'Thing') ]; });

check_test(
    sub {
        moon_test_one(
            test => 'ref_index_obj',
            instance => $instance,
            index => 0,
            func => 'ref_ind_obj',
            expected => 'Thing',
        );
    },
    {
        ok => 1,
        name => "'function: ref_ind_obj is ref - has obj index: 0 - isa_ok - Thing' isa 'Thing'",
        depth => 2,
        completed => 1,
    },
    'test mocked ref_index_obj'
);

$instance->mock('list_ind_obj', sub { return ( (bless {}, 'Thing') ); });

check_test(
    sub {
        moon_test_one(
            test => 'list_index_obj',
            instance => $instance,
            index => 0,
            func => 'list_ind_obj',
            expected => 'Thing',
        );
    },
    {
        ok => 1,
        name => "'function: list_ind_obj is list - has obj index: 0 - isa_ok - Thing' isa 'Thing'",
        depth => 2,
        completed => 1,
    },
    'test mocked list_index_obj'
);

check_test(
    sub {
        moon_test_one(
            test => 'count',
            instance => $instance,
            func => 'list_ind_obj',
            expected => 1,
        );
    },
    {
        ok => 1,
        name => "function: list_ind_obj is list - count - is - 1",
        depth => 2,
        completed => 1,
    },
    'test mocked count'
);

check_test(
    sub {
        moon_test_one(
            test => 'count_ref',
            instance => $instance,
            func => 'ref_ind_obj',
            expected => 1,
        );
    },
    {
        ok => 1,
        name => "function: ref_ind_obj is ref - count - is - 1",
        depth => 2,
        completed => 1,
    },
    'test mocked ref_count'
);

sunrise(259, confused_scratch);

1;
