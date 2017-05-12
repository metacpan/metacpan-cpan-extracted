use strictures  1;
use Test::More  0.96;
use Test::Fatal 0.003;

do {
    package TestA;
    my %called;
    my @last_args;
    sub around  { @last_args = @_; $called{around}++ }
    sub before  { @last_args = @_; $called{before}++ }
    sub after   { @last_args = @_; $called{after}++ }
    sub fun     { @last_args = @_; $called{fun}++; shift }
    sub method  { shift }
    use syntax 'sugar/callbacks' => {
        -invocant  => '$self',
        -callbacks => {
            method  => { -allow_anon => 1 },
            around  => { -before => ['$orig'] },
            before  => {},
            after   => {},
        },
    };
    use syntax 'sugar/callbacks' => {
        -invocant  => '',
        -callbacks => {
            fun     => { -only_anon => 1, -default => ['$foo'], -stmt => 1 },
        },
    };
    my $fun = fun ($x) { $x }
    ::is ref($last_args[0]), 'CODE', 'got code ref';
    ::is $last_args[0]->(23), 23, 'correct result';
    ::is $fun->(23), 23, 'correct result from returned sub';
    ::is $called{fun}, 1, 'fun called once';
    my $def_fun = fun { $foo }
    ::is ref($def_fun), 'CODE', 'code ref without signature';
    ::is $def_fun->(23), 23, 'correct result without signature';
    my @methods = (method { $self, 23 }, method { $self, 17 });
    ::is_deeply [$methods[0]->(93)], [93, 23], 'correct values';
    my $inv;
    before foo ($n) { $inv = $self; @last_args = @_; $n + 1 }
    ::is $last_args[0], 'foo', 'first name';
    ::is $last_args[1]->(qw( foo1 22 )), 23, 'first body';
    ::is_deeply \@last_args, [qw( foo1 22 )], 'first args';
    ::is $inv, 'foo1', 'first invocant';
    after  bar ($n) { $inv = $self; @last_args = @_; $n + 2 }
    ::is $last_args[0], 'bar', 'second name';
    ::is $last_args[1]->(qw( foo2 40 )), 42, 'second body';
    ::is_deeply \@last_args, [qw( foo2 40 )], 'second args';
    ::is $inv, 'foo2', 'second invocant';
    my $has_orig;
    around baz ($n) { $inv = $self; $has_orig = $orig; @last_args = @_; $n + 3 }
    ::is $last_args[0], 'baz', 'third name';
    ::is $last_args[1]->(qw( yay foo3 14 )), 17, 'third body';
    ::is_deeply \@last_args, [qw( yay foo3 14 )], 'third args';
    ::ok $has_orig, 'original callback';
    ::is $inv, 'foo3', 'third invocant';
    around qux { }
    do {
        my @returned = $last_args[1]->();
        ::ok not(@returned), 'empty sub is empty';
    };
    my $name = 'bar';
    around "my_$name" ($n) { }
    ::is $last_args[0], 'my_bar', 'dynamic names';
    around quux ($class: $n) { $has_orig = $orig; $inv = $class; $n }
    ::is $last_args[1]->('orig', foo => 23), 23, 'call with custom invocant';
    ::is $inv, 'foo', 'custom invocant';
    ::is $has_orig, 'orig', 'original in tact';
    before empty () { $self }
    ::is $last_args[1]->('foo'), 'foo', 'empty';
    before none { $self }
    ::is $last_args[1]->('foo'), 'foo', 'none';
    before no_inv (: $n) { $n }
    ::is $last_args[1]->(23), 23, 'empty invocant list';
    my $something;
    after lval ($n) :lvalue { $something = $n }
    require attributes;
    ::is_deeply [attributes::get($last_args[1])], ['lvalue'], 'lvalue';
};

do {
    package TestErrors;
    my $target = __PACKAGE__;
    ::like(
        ::exception {
            Syntax::Feature::Sugar::Callbacks->install(
                into    => $target,
                options => { -invocant => [23] },
            );
        },
        qr{ -invocant .* filled \s+ string }xi,
        'invalid -invocant',
    );
    ::like(
        ::exception {
            Syntax::Feature::Sugar::Callbacks->install(
                into    => $target,
                options => { },
            );
        },
        qr{ -callbacks .* hash \s+ ref }xi,
        'missing -callbacks',
    );
    ::like(
        ::exception {
            Syntax::Feature::Sugar::Callbacks->install(
                into    => $target,
                options => { -callbacks => { foo => [] } },
            );
        },
        qr{ foo .* hash \s+ ref }xi,
        'invalid callback options',
    );
    ::like(
        ::exception {
            Syntax::Feature::Sugar::Callbacks->install(
                into    => $target,
                options => { -callbacks => { foo => {} } },
            );
        },
        qr{ sugar .* non-existant .* foo .* TestErrors }xi,
        'non-existant callback',
    );
};

done_testing;
