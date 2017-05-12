use Test::Tester;

use Moonshine::Test qw/:all/;
use Test::MockObject;

( my $element = Test::MockObject->new )->set_isa('Moonshine::Element');

$element->mock(
    'render',
    sub {
        my $args       = $_[1];
        my $tag        = delete $args->{tag};
        my $text       = delete $args->{data} // '';
        my $attributes = '';
        map {
            $attributes .= ' ';
            $attributes .= sprintf( '%s="%s"', $_, $args->{$_} );
        } keys %{$args};
        return sprintf( '<%s%s>%s</%s>', $tag, $attributes, $text, $tag );
    }
);

( my $instance = Test::MockObject->new )->set_isa('Moonshine::Component');

$instance->mock(
    'p',
    sub {
        my $args = $_[1];
        return ( Test::MockObject->new )
          ->mock( 'render',
            sub { $element->render( { tag => 'p', %{$args} } ) } );
    }
);

( my $div = Test::MockObject->new )->set_isa('Moonshine::Element');
$div->mock(
    'render',
    sub {
        $element->render( { tag => 'div', class => 'test', data => 'test' } );
    }
);

$instance->mock(
    'broken',
    sub {
        my $args = $_[1];
        return ( Test::MockObject->new )
          ->mock( 'render', sub { $element->render( { %{$args} } ) } );
    }
);

my $arrayref = [ { name => 'one' }, { name => 'two' } ];
$instance->mock( 'arrayref', sub { return $arrayref } );

my $hashref = { name => 'one', second => 'two' };
$instance->mock( 'hashref', sub { return $hashref } );

my @array = (qw/one two three/);
$instance->mock( 'array', sub { return @array } );

my %hash = ( map { $_ => 1 } qw/one two three/ );
$instance->mock( 'hash', sub { return %hash } );

$instance->mock( 'obj', sub { return bless {}, 'Test::Moon'; } );

$instance->mock( 'catch', sub { die 'a horrible death'; } );

$instance->mock( 'true', sub { return 1; } );

$instance->mock( 'false', sub { return 0; } );

$instance->mock( 'undefined', sub { return undef; } );

$instance->mock( 'ref_scalar_key', sub { return { thing => 1234 }; } );

$instance->mock( 'ref_ref_key',
    sub { return { thing => { okay => 'yes' } }; } );

$instance->mock( 'ref_refa_key',
    sub { return { thing => [ 'okay', 'yes' ] }; } );

$instance->mock( 'ref_index',
    sub { return [ 'thing', { thing => 'okay' }, 'yes' ] } );

$instance->mock(
    'ref_like_key',
    sub {
        return {
            exception => 'mehhh the world has ended line 123 some_method.' };
    }
);

$instance->mock(
    'ref_like_ref',
    sub {
        return [ 'exception',
            'mehhh the world has ended line 123 some_method.' ];
    }
);

$instance->mock(
    'list_like_ref',
    sub {
        return ( 'exception',
            'mehhh the world has ended line 123 some_method.' );
    }
);

$instance->mock( 'list_index',
    sub { return ( 'thing', { thing => 'okay' }, 'yes' ) } );

$instance->mock(
    'list_key',
    sub {
        return ( 'thing' => { thing => 'okay' },
            'yes' => 'okay something slow' );
    }
);

moon_test(
    instance     => $instance,
    name         => 'The World',
    instructions => [
        {
            test => 'render',
            func => 'p',
            args => {
                data => 'test',
            },
            expected => '<p>test</p>'
        },
        {
            test     => 'ref',
            instance => $instance,
            func     => 'arrayref',
            expected => $arrayref,
        },
        {
            test     => 'ref',
            instance => $instance,
            func     => 'hashref',
            expected => $hashref,
        },
        {
            test     => 'array',
            instance => $instance,
            func     => 'array',
            expected => [qw/one two three/],
        },
        {
            test     => 'hash',
            instance => $instance,
            func     => 'hash',
            expected => \%hash,
        },
        {
            test     => 'obj',
            instance => $instance,
            func     => 'obj',
            expected => 'Test::Moon',
        },
    ],
);

(my $life = Test::MockObject->new)->mock('arrayref', sub{ [ 'one', 'two', 'three' ] });

moon_test(
    name => 'Arrayref',
    instance => $life,
    instructions => [
        {
            test => 'ok',
            func => 'arrayref',
            subtest => [
                {
                    test => 'count_ref',
                    expected => 3,
                },
                {
                    test => 'ref_index_scalar',
                    index => 0,
                    expected => 'one',
                },
                {
                    test => 'ref_index_scalar',
                    index => 1,
                    expected => 'two',
                },
                {
                    test => 'ref_index_scalar',
                    index => 2,
                    expected => 'three',
                },
            ]
        }
    ]

);

check_tests(
    sub {
        moon_test(
            instance     => $instance,
            name         => 'The World is ending',
            instructions => [
                {
                    test => 'render',
                    func => 'p',
                    args => {
                        data => 'test',
                    },
                    expected => '<p>test</p>'
                },
                {
                    test     => 'ref',
                    instance => $instance,
                    func     => 'arrayref',
                    expected => $arrayref,
                },
                {
                    test     => 'ref',
                    instance => $instance,
                    func     => 'hashref',
                    expected => $hashref,
                },
                {
                    test     => 'array',
                    instance => $instance,
                    func     => 'array',
                    expected => [qw/one two three/],
                },
                {
                    test     => 'hash',
                    instance => $instance,
                    func     => 'hash',
                    expected => \%hash,
                },
                {
                    test     => 'obj',
                    instance => $instance,
                    func     => 'obj',
                    expected => 'Test::Moon',
                },
                {
                    catch    => 1,
                    instance => $instance,
                    func     => 'catch',
                    expected => 'a horrible death',
                },
                {
                    test     => 'true',
                    instance => $instance,
                    func     => 'true',
                },
                {
                    test     => 'false',
                    instance => $instance,
                    func     => 'false',
                },
                {
                    test     => 'undef',
                    instance => $instance,
                    func     => 'undefined',
                },
                {
                    test     => 'ref_key_scalar',
                    instance => $instance,
                    func     => 'ref_scalar_key',
                    key      => 'thing',
                    expected => 1234,
                },
                {
                    test     => 'ref_key_ref',
                    instance => $instance,
                    func     => 'ref_ref_key',
                    key      => 'thing',
                    expected => { okay => 'yes' },
                },
                {
                    test     => 'ref_key_ref',
                    instance => $instance,
                    func     => 'ref_refa_key',
                    key      => 'thing',
                    expected => [ 'okay', 'yes' ],
                },
                {
                    test     => 'ref_index_scalar',
                    instance => $instance,
                    func     => 'ref_index',
                    index    => 0,
                    expected => 'thing',
                },
                {
                    test     => 'ref_index_ref',
                    instance => $instance,
                    func     => 'ref_index',
                    index    => 1,
                    expected => { thing => 'okay' },
                },
                {
                    test     => 'ref_key_like',
                    instance => $instance,
                    func     => 'ref_like_key',
                    key      => 'exception',
                    expected => 'mehhh the world has ended',
                },
                {
                    test     => 'ref_index_like',
                    instance => $instance,
                    func     => 'ref_like_ref',
                    index    => 1,
                    expected => 'mehhh the world has ended',
                },
                {
                    test     => 'list_index_like',
                    instance => $instance,
                    func     => 'list_like_ref',
                    index    => 1,
                    expected => 'mehhh the world has ended',
                },
                {
                    test     => 'list_index_scalar',
                    instance => $instance,
                    func     => 'list_index',
                    index    => 0,
                    expected => 'thing',
                },
                {
                    test     => 'list_index_ref',
                    instance => $instance,
                    func     => 'list_index',
                    index    => 1,
                    expected => { thing => 'okay' },
                },
                {
                    test     => 'list_key_scalar',
                    instance => $instance,
                    func     => 'list_key',
                    key      => 'yes',
                    expected => 'okay something slow',
                },
                {
                    test     => 'list_key_ref',
                    instance => $instance,
                    func     => 'list_key',
                    key      => 'thing',
                    expected => { thing => 'okay' },
                },
                {
                    test     => 'list_key_like',
                    instance => $instance,
                    func     => 'list_key',
                    key      => 'yes',
                    expected => 'something',
                },
            ],
        );
    },
    [
        {
            ok        => 1,
            name      => "render instance: <p>test</p>",
            depth     => 4,
            completed => 1,
        },
        {
            ok        => 1,
            name      => "function: arrayref is ref - is_deeply",
            depth     => 3,
            completed => 1,
        },
        {
            ok        => 1,
            name      => "function: hashref is ref - is_deeply",
            depth     => 3,
            completed => 1,
        },
        {
            ok        => 1,
            name      => "function: array is array - reference - is_deeply",
            depth     => 3,
            completed => 1,
        },
        {
            ok        => 1,
            name      => "function: hash is hash - reference - is_deeply",
            depth     => 3,
            completed => 1,
        },
        {
            ok        => 1,
            name      => "'function: obj is Object - blessed - is - Test::Moon' isa 'Test::Moon'",
            depth     => 3,
            completed => 1,
        },
        {
            ok        => 1,
            name      => "catch is like - a horrible death",
            depth     => 3,
            completed => 1,
        },
        {
            ok        => 1,
            name      => "function: true is true - 1",
            depth     => 3,
            completed => 1,
        },
        {
            ok        => 1,
            name      => "function: false is false - 0",
            depth     => 3,
            completed => 1,
        },
        {
            ok        => 1,
            name      => "function: undefined is undef",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: ref_scalar_key is ref - has scalar key: thing - is - 1234",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: ref_ref_key is ref - has ref key: thing - is_deeply - ref",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: ref_refa_key is ref - has ref key: thing - is_deeply - ref",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
              "function: ref_index is ref - has scalar index: 0 - is - thing",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
              "function: ref_index is ref - has ref index: 1 - is_deeply - ref",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: ref_like_key is ref - has scalar key: exception - like - mehhh the world has ended",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: ref_like_ref is ref - has scalar index: 1 - like - mehhh the world has ended",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: list_like_ref is list - has scalar index: 1 - like - mehhh the world has ended",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
              "function: list_index is list - has scalar index: 0 - is - thing",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: list_index is list - has ref index: 1 - is_deeply - ref",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: list_key is list - has scalar key: yes - is - okay something slow",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: list_key is list - has ref key: thing - is_deeply - ref",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"function: list_key is list - has scalar key: yes - like - something",
            depth     => 3,
            completed => 1,
        },
        {
            ok => 1,
            name =>
"moon_test: The World is ending - tested 23 instructions - success: 23 - failure: 0",
            depth     => 2,
            completed => 1,
        }
    ],
    "moon_test test"
);

sunrise( 89, touchy);

1;
