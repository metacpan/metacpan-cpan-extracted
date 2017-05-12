use Test::More tests => 29;
use Test::Deep;

do {
    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has '_options' => (
        metaclass => 'Collection::List',
        is        => 'rw',
        isa       => 'ArrayRef',
        init_arg  => 'options',
        default   => sub { [] },
        provides  => {
            count    => 'num_options',
            empty    => 'has_options',
            find     => 'find_option',
            map      => 'map_options',
            grep     => 'filter_options',
            elements => 'options',
            join     => 'join_options',
            get      => 'get_option_at',
            first    => 'get_first_option',
            last     => 'get_last_option',
        },
        curries   => {
            grep => { less_than_five => [ sub { $_ < 5 } ] },
            map  => { up_by_one      => [ sub { $_ + 1 } ] },
            join => { dashify        => [ '-' ] },
        },
    );

    has 'animals' => (
        metaclass => 'Collection::List',
        is        => 'rw',
        isa       => 'ArrayRef',
        curries   => {
            grep => {
                double_length_of => sub {
                    my ($self, $code, $args) = @_;
                    $code->($self, sub { length($_) == length($args) * 2 });
                },
            },
        },
    );
};

my $obj = MyClass->new(options => [ 1..10 ]);

my @providers = qw(
    num_options has_options find_option map_options filter_options
    options join_options get_option_at get_first_option get_last_option
);
for my $method (@providers) {
    can_ok $obj => $method;
}

my @curries = qw(less_than_five up_by_one dashify double_length_of);
for my $method (@curries) {
    can_ok $obj => $method;
}

cmp_deeply $obj->_options => [ 1..10 ], 'get value ok';

# provides
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
cmp_deeply [ $obj->less_than_five ] => [ 1..4 ], 'curries grep ok';
cmp_deeply [ $obj->up_by_one ] => [ 2..11 ], 'curries map ok';
is $obj->dashify => '1-2-3-4-5-6-7-8-9-10', 'curries join ok';

$obj->animals([qw(cat duck horse cattle gorilla elephant flamingo kangaroo)]);
cmp_deeply
    [ sort $obj->double_length_of('fish') ],
    [ sort qw(elephant flamingo kangaroo) ],
    'curries grep with subref ok';
