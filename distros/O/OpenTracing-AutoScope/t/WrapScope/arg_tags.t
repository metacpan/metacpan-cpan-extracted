use Test::Most;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;

use lib 't/lib';
use Line::Storage ':ALL';

use OpenTracing::WrapScope 'foo($name, $limit, @rest)';

sub foo { }

foo('john', 15, 'x', 'y', 'z');
foo('mike', 1, 'zzz');
foo('shawn');

global_tracer_cmp_easy(
    [
        {
            operation_name => 'main::foo',
            tags           => superhashof({
                'arguments.name'  => 'john',
                'arguments.limit' => 15,
                'arguments.rest.0' => 'x',
                'arguments.rest.1' => 'y',
                'arguments.rest.2' => 'z',
            }),
        },
        {
            operation_name => 'main::foo',
            tags           => superhashof({
                'arguments.name'  => 'mike',
                'arguments.limit' => 1,
                'arguments.rest.0'  => 'zzz',
            }),
        },
        {
            operation_name => 'main::foo',
            tags           => superhashof({
                'arguments.name'  => 'shawn',
            }),
        },
    ],
    'signature in import arguments'
);

my @cases = (
    {
        signature => '$x, undef, $y',
        call_args => [ 1, 2, 3 ],
        tags      => {
            'arguments.x' => '1',
            'arguments.y' => '3',
        },
    },
    {
        signature => '$user, %kv_pairs',
        call_args => [ 'tester', a => 1, b => 2, c => 3 ],
        tags => {
            'arguments.user'       => 'tester',
            'arguments.kv_pairs.a' => 1,
            'arguments.kv_pairs.b' => 2,
            'arguments.kv_pairs.c' => 3,
        },
    },
    {
        signature => '$user, \%kv_pairs',
        call_args => [ 'tester', { a => 1, b => 2, c => 3 } ],
        tags => {
            'arguments.user'       => 'tester',
            'arguments.kv_pairs.a' => 1,
            'arguments.kv_pairs.b' => 2,
            'arguments.kv_pairs.c' => 3,
        },
    },
    {
        signature => '%params{ "user", "date" }',
        call_args => [ user => 'mike', password => 'hunter2', date => '2020-01-12' ],
        tags => {
            'arguments.params.user' => 'mike',
            'arguments.params.date' => '2020-01-12',
        },
    },
    {
        signature => '\%params{ "user", "date" }',
        call_args => [{ user => 'mike', password => 'hunter2', date => '2020-01-12' }],
        tags => {
            'arguments.params.user' => 'mike',
            'arguments.params.date' => '2020-01-12',
        },
    },
    {
        signature => '$x, $y, \@extras',
        call_args => [ 12, 34, [ 1, 2, 3, 4, 5 ] ],
        tags => {
            'arguments.x'        => 12,
            'arguments.y'        => 34,
            'arguments.extras.0' => 1,
            'arguments.extras.1' => 2,
            'arguments.extras.2' => 3,
            'arguments.extras.3' => 4,
            'arguments.extras.4' => 5,
        },
    },
    {
        signature => '$x, $y, \@extras[ 0, 2 .. 4 ]',
        call_args => [ 12, 34, [ 1, 2, 3, 4, 5 ] ],
        tags => {
            'arguments.x'        => 12,
            'arguments.y'        => 34,
            'arguments.extras.0' => 1,
            'arguments.extras.2' => 3,
            'arguments.extras.3' => 4,
            'arguments.extras.4' => 5,
        },
    },
    {
        signature => '$x, $y, @extras',
        call_args => [ 12, 34, ( 1, 2, 3, 4, 5 ) ],
        tags => {
            'arguments.x'        => 12,
            'arguments.y'        => 34,
            'arguments.extras.0' => 1,
            'arguments.extras.1' => 2,
            'arguments.extras.2' => 3,
            'arguments.extras.3' => 4,
            'arguments.extras.4' => 5,
        },
    },
    {
        signature => '$x, $y, @extras[ 0, 2 .. 4 ]',
        call_args => [ 12, 34, ( 1, 2, 3, 4, 5 ) ],
        tags => {
            'arguments.x'        => 12,
            'arguments.y'        => 34,
            'arguments.extras.0' => 1,
            'arguments.extras.2' => 3,
            'arguments.extras.3' => 4,
            'arguments.extras.4' => 5,
        },
    },
    {
        signature => '$x, $y',
        call_args => [ 1, undef ],
        tags => {
            'arguments.x' => 1,
            'arguments.y' => 'undef',
        },
    },
    {
        signature => '%params{ "user", "date", "nope" }',
        call_args => [ user => 'mike', password => 'hunter2', date => '2020-01-12' ],
        tags => {
            'arguments.params.user' => 'mike',
            'arguments.params.date' => '2020-01-12',
        },
    },
    {
        signature => '\%params{ "user", "date", "nope" }',
        call_args => [{ user => 'mike', password => 'hunter2', date => '2020-01-12' }],
        tags => {
            'arguments.params.user' => 'mike',
            'arguments.params.date' => '2020-01-12',
        },
    },
    {
        signature => '%params{ "nope" }',
        call_args => [ user => 'mike', password => 'hunter2' ],
        tags => {},
    },
    {
        signature => '\%params{ "nope" }',
        call_args => [{ user => 'mike', password => 'hunter2' }],
        tags => {},
    },
    {
        signature => '@params[ 0, 5 ]',
        call_args => [ 'x', 'y', 'z'],
        tags => {
            'arguments.params.0' => 'x',
        },
    },
    {
        signature => '\@params[ 0, 5 ]',
        call_args => [ [ 'x', 'y', 'z' ] ],
        tags => {
            'arguments.params.0' => 'x',
        },
    },
);

foreach (@cases) {
    my ($sig, $args, $tags) = @$_{qw[ signature call_args tags ]};

    reset_spans();
    my $coderef = OpenTracing::WrapScope::wrapped(sub { }, $sig); BEGIN { remember_line('source') }
    $coderef->(@$args);                                           BEGIN { remember_line('call') }

    my $args_str = join ', ', map { $_ // 'undef' } @$args;
    global_tracer_cmp_easy([
        {
            operation_name => 'main::__ANON__',
            tags           => {
                'caller.file'    => __FILE__,
                'caller.line'    => recall_line('call'),
                'caller.package' => __PACKAGE__,
                'source.file'    => __FILE__,
                'source.line'    => recall_line('source'),
                'source.package' => __PACKAGE__,
                'source.subname' => '__ANON__',
                %$tags,
            },
        },
    ], "($sig) called with [$args_str]");
}

my $args_hashref = OpenTracing::WrapScope::wrapped(sub { }, '\%args');
lives_ok {
    $args_hashref->(a => 1);
    $args_hashref->([]);
    $args_hashref->();
} 'hashref signature does not die';

my $args_hash = OpenTracing::WrapScope::wrapped(sub { }, '%args');
lives_ok {
    $args_hash->({a => 1});
    $args_hash->([]);
    $args_hash->();
} 'hash signature does not die';

my $args_arrayref = OpenTracing::WrapScope::wrapped(sub { }, '\@args');
lives_ok {
    $args_arrayref->(1, 2, 3);
    $args_arrayref->({});
    $args_arrayref->();
} 'arrayref signature does not die';

my $args_array = OpenTracing::WrapScope::wrapped(sub { }, '\@args');
lives_ok {
    $args_array->([1, 2, 3]);
    $args_array->({});
    $args_array->();
} 'array signature does not die';

my @invalid_signatures = (
    '%params{ "x" "y" }',
    '$x $y $z',
    '@args, @nothing',
    'no_sigils',
    '$x :,: $y :,: $z',
    '%params{@args}',
    ' ',
);

foreach my $sig (@invalid_signatures) {
    throws_ok {
        OpenTracing::WrapScope::wrapped(sub { }, $sig);
    } qr/Failed to parse signature/, "($sig) didn't parse";
}

done_testing();
