use Test2::V0;

use Sub::Meta;
use Sub::Identify;

subtest 'non sub' => sub {
    my $meta = Sub::Meta->new;
    is $meta->sub, undef, 'sub';
    is $meta->subname, undef, 'subname';
    is $meta->fullname, undef, 'fullname';
    is $meta->stashname, undef, 'stashname';
    is $meta->file, '', 'file';
    is $meta->line, undef, 'line';
    is $meta->is_constant, undef, 'is_constant';
    is $meta->prototype, '', 'prototype';
    is $meta->attribute, undef, 'prototype';
    ok !$meta->is_method, 'is_method';
    is $meta->parameters, undef, 'parameters';
    is $meta->returns, undef, 'returns';
};

subtest 'has sub' => sub {

    sub hello($$) :method { }

    subtest 'getter' => sub {
        my $meta = Sub::Meta->new(sub => \&hello);
        is $meta->sub, \&hello, 'sub';
        is $meta->subname, 'hello', 'subname';
        is $meta->fullname, 'main::hello', 'fullname';
        is $meta->stashname, 'main', 'stashname';
        is $meta->file, 't/01_meta.t', 'file';
        is $meta->line, 24, 'line';
        ok !$meta->is_constant, 'is_constant';
        is $meta->prototype, '$$', 'prototype';
        is $meta->attribute, ['method'], 'attribute';
        ok !$meta->is_method, 'is_method';
        is $meta->parameters, undef, 'parameters';
        is $meta->returns, undef, 'returns';
    };

    subtest 'setter' => sub {
        sub hello2 { }

        my $meta = Sub::Meta->new(sub => \&hello);
        is $meta->set_sub(\&hello2), $meta, 'set_sub';
        is $meta->sub, \&hello2, 'subname';

        is $meta->set_subname('world'), $meta, 'set_subname';
        is $meta->subname, 'world', 'subname';
        is $meta->stashname, 'main', 'stashname';
        is $meta->fullname, 'main::world', 'fullname';
        is $meta->subinfo, ['main', 'world'], 'subinfo';

        is $meta->set_fullname('foo::bar::baz'), $meta, 'set_fullname';
        is $meta->subname, 'baz', 'subname';
        is $meta->fullname, 'foo::bar::baz', 'fullname';
        is $meta->stashname, 'foo::bar', 'stashname';
        is $meta->subinfo, ['foo::bar', 'baz'], 'subinfo';

        is $meta->set_stashname('test'), $meta, 'set_stashname';
        is $meta->subname, 'baz', 'subname';
        is $meta->fullname, 'test::baz', 'fullname';
        is $meta->stashname, 'test', 'stashname';
        is $meta->subinfo, ['test', 'baz'], 'subinfo';

        is $meta->set_subinfo(['hoge', 'fuga']), $meta, 'set_subinfo';
        is $meta->subname, 'fuga', 'subname';
        is $meta->fullname, 'hoge::fuga', 'fullname';
        is $meta->stashname, 'hoge', 'stashname';
        is $meta->subinfo, ['hoge', 'fuga'], 'subinfo';

        is $meta->set_file('test/file.t'), $meta, 'set_file';
        is $meta->file, 'test/file.t', 'file';
        is $meta->set_line(999), $meta, 'set_line';
        is $meta->line, 999, 'line';
        is $meta->set_is_constant(!!1), $meta, 'set_is_constant';
        is $meta->is_constant, !!1, 'is_constant';
        is $meta->set_prototype('$@'), $meta, 'set_prototype';
        is $meta->set_attribute(['foo','bar']), $meta, 'set_attribute';
        is $meta->attribute, ['foo','bar'], 'attribute';
        is $meta->set_is_method(!!1), $meta, 'set_is_method';
        ok $meta->is_method, 'is_method';
        is $meta->set_parameters(args => []), $meta, 'set_parameters';
        is $meta->parameters, Sub::Meta::Parameters->new(args => []), 'parameters';
        is $meta->set_args(['Int']), $meta, 'set_args';
        is $meta->args, Sub::Meta::Parameters->new(args => ['Int'])->args, 'args';
        is $meta->set_nshift(1), $meta, 'set_nshift';
        is $meta->nshift, 1, 'nshift';
        is $meta->set_slurpy('Str'), $meta, 'set_slurpy';
        is $meta->slurpy, Sub::Meta::Param->new('Str'), 'slurpy';
        is $meta->set_returns([]), $meta, 'set_returns';
        is $meta->returns, Sub::Meta::Returns->new([]), 'returns';
    };

    subtest 'apply' => sub {
        sub hello3 { "HELLO!!" }

        my $meta = Sub::Meta->new(sub => \&hello3);
        is $meta->apply_subname('HELLO'), $meta, 'apply_subname';
        is $meta->subname, 'HELLO', 'subname';
        is $meta->stashname, 'main', 'stashname';
        is $meta->fullname, 'main::HELLO', 'fullname';
        is [ Sub::Identify::get_code_info(\&hello3) ], ['main','HELLO'], 'build_subinfo';

        is $meta->apply_prototype('$'), $meta, 'apply_prototype';
        is $meta->prototype, '$', 'prototype';
        is $meta->_build_prototype, '$', 'build_prototype';

        is $meta->attribute, [], 'attribute';
        is $meta->apply_attribute('lvalue'), $meta, 'apply_attribute';
        is $meta->attribute, ['lvalue'], 'attribute';
        is $meta->apply_attribute('method'), $meta, 'apply_attribute';
        is $meta->attribute, ['lvalue', 'method'], 'attribute/added';

        like dies { $meta->apply_attribute('foo') }, qr/Invalid CODE attribute: foo/, 'invalid attribute';

        like dies { Sub::Meta->new->apply_subname('hello') }, qr/apply_subname requires subroutine reference/, 'apply_subname requires subroutine reference';

        like dies { Sub::Meta->new->apply_prototype('$$') }, qr/apply_prototype requires subroutine reference/, 'apply_prototype requires subroutine reference';

        like dies { Sub::Meta->new->apply_attribute('lvalue') }, qr/apply_attribute requires subroutine reference/, 'apply_attribute requires subroutine reference';
    };

    subtest 'apply_meta' => sub {
        sub hello4 { }

        my $meta = Sub::Meta->new(sub => \&hello4);
        my $other = Sub::Meta->new(
            subname   => 'other_hello',
            prototype => '$',
            attribute => ['lvalue', 'method'],
        );

        is [ Sub::Identify::get_code_info(\&hello4) ], ['main','hello4'];
        is Sub::Util::prototype(\&hello4), undef;
        is [ attributes::get(\&hello4) ], [];

        is $meta->apply_meta($other), $meta, 'apply_meta';
        is $meta->subname, 'other_hello';
        is $meta->prototype, '$',
        is $meta->attribute, ['lvalue', 'method'];

        is [ Sub::Identify::get_code_info(\&hello4) ], ['main','other_hello'];
        is Sub::Util::prototype(\&hello4), '$';
        is [ attributes::get(\&hello4) ], ['lvalue', 'method'];
    };
};

subtest 'new' => sub {
    sub test_new { }
    is(Sub::Meta->new({ sub => \&test_new})->sub, \&test_new, 'args hashref');

    is(Sub::Meta->new(subname => 'foo')->subname, 'foo', 'subname args');
    is(Sub::Meta->new(stashname => 'Bar')->stashname, 'Bar', 'stashname args');
    is(Sub::Meta->new(fullname => 'Baz::boo')->fullname, 'Baz::boo', 'fullname args');
};

subtest 'subname/stashname/fullname' => sub {
    my $meta = Sub::Meta->new;
    is $meta->subname, undef, 'undef subname';
    is $meta->stashname, undef, 'undef stashname';
    is $meta->fullname, undef, 'undef fullname';

    is $meta->set_subname('foo'), $meta;
    is $meta->subname, 'foo', 'subname';
    is $meta->stashname, undef, 'undef stashname';
    is $meta->fullname, '::foo', 'fullname';

    is $meta->set_stashname('Bar'), $meta;
    is $meta->subname, 'foo', 'subname';
    is $meta->stashname, 'Bar', 'stashname';
    is $meta->fullname, 'Bar::foo', 'fullname';

    is $meta->set_subname(undef), $meta;
    is $meta->subname, undef, 'undef subname';
    is $meta->stashname, 'Bar', 'stashname';
    is $meta->fullname, 'Bar::', 'fullname';

    is $meta->set_fullname('Hello::world'), $meta;
    is $meta->subname, 'world', 'subname';
    is $meta->stashname, 'Hello', 'stashname';
    is $meta->fullname, 'Hello::world', 'fullname';
};

subtest 'constant' => sub {
    {
        use constant PI => 4 * atan2(1, 1);
        my $m = Sub::Meta->new(sub => \&PI);
        is $m->is_constant, 1;
    }

    {
        sub one() { 1 }
        my $m = Sub::Meta->new(sub => \&one);
        is $m->is_constant, 1;
    }
};

subtest 'set_parameters/args/returns' => sub {
    my $meta = Sub::Meta->new;
    my $obj = bless {}, 'Some::Object';
    my $parameters = Sub::Meta::Parameters->new(args => [{ type => $obj }]);

    $meta->set_parameters(args => [$obj]);
    is $meta->parameters, $parameters,
        'if $obj is not Sub::Meta::Parameters, $obj will be treated as type';

    $meta->set_args([$obj]);
    is $meta->args, $parameters->args, 'set_args';

    {
        my $meta = Sub::Meta->new;
        is $meta->parameters, undef;
        $meta->set_args([$obj]);
        is $meta->args, $parameters->args, 'set_args when no parameters';
    }

    {
        my $meta = Sub::Meta->new;
        like dies { $meta->set_parameters($obj) },
        qr/object must be Sub::Meta::Parameters/, 'invalid parameters';
    }

    $meta->set_returns($obj);
    is $meta->returns, Sub::Meta::Returns->new($obj),
        'if $obj is not Sub::Meta::Returns, $obj will be treated as type';
};

subtest 'set invalid fullname' => sub {
    my $meta = Sub::Meta->new;

    is $meta->set_fullname('invalid'), $meta, 'set_fullname';
    is $meta->subinfo, [], 'subinfo';
};

subtest 'set_subinfo' => sub {
    my $meta = Sub::Meta->new;

    is $meta->subinfo, [], 'subinfo';

    is $meta->set_subinfo(['foo', 'bar']), $meta, 'set_subinfo';
    is $meta->subinfo, ['foo','bar'], 'subinfo';

    is $meta->set_subinfo('hoge', 'fuga'), $meta, 'set_subinfo';
    is $meta->subinfo, ['hoge','fuga'], 'subinfo';
};


subtest 'set_sub' => sub {
    my $meta = Sub::Meta->new;

    is $meta->subinfo, [], 'subinfo 1';

    $meta->set_sub(\&hello);
    is $meta->subinfo, ['main', 'hello'], 'subinfo 2';

    $meta->set_sub(\&hello2);
    is $meta->subinfo, ['main', 'hello2'], 'subinfo 3';
};

subtest 'set_nshift' => sub {
    my $meta = Sub::Meta->new(args => ['Str']);
    $meta->set_nshift(1);
    is $meta->nshift, 1;

    $meta->set_is_method(1);
    $meta->set_nshift(1);
    is $meta->nshift, 1;

    like dies { $meta->set_nshift(0) },
    qr/nshift of method cannot be zero/, 'invalid nshift';
};

subtest 'invocant/invocants/set_invocant' => sub {
    my $invocant = Sub::Meta::Param->new(name => '$self');
    my $p1 = Sub::Meta::Param->new(type => 'Str');

    my $meta = Sub::Meta->new(args => [$p1]);
    is $meta->all_args, [ $p1 ];
    is $meta->invocant, undef;

    is $meta->set_invocant($invocant), $meta;
    is $meta->invocant, $invocant;
    is $meta->invocants, [ $invocant ];

    is $meta->all_args, [ $invocant, $p1 ];
    is $meta->args, [$p1];
};

done_testing;
