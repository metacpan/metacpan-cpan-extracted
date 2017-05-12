use Test::More tests => 52;
use Test::Deep;

{
    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has '_options' => (
        metaclass => 'Collection::Array',
        is        => 'rw',
        isa       => 'ArrayRef',
        init_arg  => 'options',
        default   => sub { [] },
        provides  => {
            push    => 'add_options',
            pop     => 'remove_last_option',
            shift   => 'remove_first_option',
            unshift => 'insert_options',
            get     => 'get_option_at',
            set     => 'set_option_at',
            clear   => 'clear_options',
            delete  => 'delete_option_at',
            insert  => 'insert_option_at',
            splice  => 'splice_options',
            # with Collection::List
            count    => 'num_options',
            empty    => 'has_options',
            find     => 'find_option',
            map      => 'map_options',
            grep     => 'filter_options',
            elements => 'options',
            join     => 'join_options',
            first    => 'get_first_option',
            last     => 'get_last_option',
        },
        curries   => {
            push    => {
                add_options_with_speed => ['funrolls', 'funbuns'],
            },
            unshift => {
                prepend_prerequisites_along_with => ['first', 'second'],
            },
        },
    );
}

my $obj = MyClass->new(options => [ 1..10 ]);

my @providers = qw(
    add_options remove_last_option remove_first_option insert_options
    get_option_at set_option_at
    clear_options delete_option_at insert_option_at splice_options

    num_options has_options find_option map_options filter_options
    options join_options get_first_option get_last_option
);
for my $method (@providers) {
    can_ok $obj => $method;
}

my @curries = qw(add_options_with_speed prepend_prerequisites_along_with);
for my $method (@curries) {
    can_ok $obj => $method;
}

cmp_deeply $obj->_options => [ 1..10 ], 'get value ok';

# provides
is $obj->remove_last_option => 10, 'provides pop ok';
is $obj->remove_first_option => 1, 'provides shift ok';

$obj->insert_options(1, 2, 3);
$obj->add_options(10, 20);
is $obj->get_option_at(0) => 1, 'provides unshift and get ok (1)';
is $obj->get_option_at(1) => 2, 'provides unshift and get ok (2)';
is $obj->get_option_at(2) => 3, 'provides unshift and get ok (3)';
is $obj->get_option_at(-1) => 20, 'provides push and get ok (-1)';
is $obj->get_option_at(-2) => 10, 'provides push and get ok (-2)';
is $obj->num_options => 13, 'provides push, unshift and count ok';

$obj->set_option_at(1, 100);
is $obj->get_option_at(1) => 100, 'provides set and get ok';

$obj->clear_options;
cmp_deeply $obj->_options => [], 'provides clear ok';

$obj = MyClass->new(options => [ 1..10 ]);
is $obj->num_options => 10, 'count ok (10)';
is $obj->delete_option_at(1) => 2, 'provides delete ok';
is $obj->num_options => 9, 'count again ok (9)';
$obj->insert_option_at(1, 20);
is $obj->num_options => 10, 'count again ok (10)';
is $obj->get_option_at(1) => 20, 'provides insert ok (20)';

cmp_deeply [ $obj->splice_options(2, 3, 100, 200) ] => [ 3, 4, 5 ], 'provides splice ok';
is $obj->num_options => 9, 'spliced count ok';
cmp_deeply [ $obj->options ] => [ 1, 20, 100, 200, 6, 7, 8, 9, 10 ], 'spliced elements ok';

# provides (with Collection::List)
$obj = MyClass->new(options => [ 1..10 ]);

ok $obj->has_options, 'provides empty ok';
is $obj->num_options => 10, 'provides count ok';
is $obj->get_option_at(0) => 1, 'provides get ok';
is $obj->get_first_option => 1, 'provides first ok';
is $obj->get_last_option => 10, 'provides last ok';

cmp_deeply
    [ $obj->filter_options(sub { $_[0] % 2 == 0 }) ],
    [ 2, 4, 6, 8, 10 ],
    'provides grep ok';

cmp_deeply
    [ $obj->map_options(sub { $_[0] * 2 }) ],
    [ 2, 4, 6, 8, 10, 12, 14, 16, 18, 20 ],
    'provides map ok';

is $obj->find_option(sub { $_[0] % 2 == 0 }) => 2, 'provides find ok';

cmp_deeply [ $obj->options ] => [ 1..10 ], 'provides elements ok';

is $obj->join_options(':') => '1:2:3:4:5:6:7:8:9:10', 'provides join ok';

# curries
$obj->add_options_with_speed('compatible', 'safe');
cmp_deeply
    [ $obj->options ],
    [qw(1 2 3 4 5 6 7 8 9 10 funrolls funbuns compatible safe)],
    'curries push ok';

$obj->prepend_prerequisites_along_with('foobar');
cmp_deeply
    [ $obj->options ],
    [qw(first second foobar 1 2 3 4 5 6 7 8 9 10 funrolls funbuns compatible safe)],
    'curries unshift ok';
