use Test2::V0;

use Sub::Meta;

subtest 'non sub' => sub {
    my $meta = Sub::Meta->new;
    is $meta->sub, undef, 'sub';
    is $meta->subname, '', 'subname';
    is $meta->fullname, '', 'fullname';
    is $meta->stashname, '', 'stashname';
    is $meta->file, '', 'file';
    is $meta->line, undef, 'line';
    is $meta->is_constant, undef, 'is_constant';
    is $meta->prototype, '', 'prototype';
    is $meta->attribute, undef, 'prototype';
    is $meta->is_method, undef, 'is_method';
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
        is $meta->line, 23, 'line';
        ok !$meta->is_constant, 'is_constant';
        is $meta->prototype, '$$', 'prototype';
        is $meta->attribute, ['method'], 'attribute';
        is $meta->is_method, undef, 'is_method';
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
        is $meta->set_fullname('test::world'), $meta, 'set_fullname';
        is $meta->fullname, 'test::world', 'fullname';
        is $meta->set_stashname('test'), $meta, 'set_stashname';
        is $meta->stashname, 'test', 'stashname';
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
        is $meta->is_method, !!1, 'is_method';
        is $meta->set_parameters(args => []), $meta, 'set_parameters';
        is $meta->parameters, Sub::Meta::Parameters->new(args => []), 'parameters';
        is $meta->set_returns([]), $meta, 'set_returns';
        is $meta->returns, Sub::Meta::Returns->new([]), 'returns';
    };

    subtest 'apply' => sub {
        sub hello3 { "HELLO!!" }

        my $meta = Sub::Meta->new(sub => \&hello3);
        is $meta->apply_subname('HELLO'), $meta, 'apply_subname';
        is $meta->subname, 'HELLO', 'subname';
        is $meta->_build_subname, 'HELLO', 'build_subname';

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
};

subtest 'new' => sub {
    sub test_new { }
    is(Sub::Meta->new({ sub => \&test_new})->sub, \&test_new, 'args hashref');
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

subtest 'set_parameters/returns' => sub {
    my $meta = Sub::Meta->new;

    my $obj = bless {}, 'Some::Object';
    $meta->set_parameters($obj);
    is $meta->parameters, $obj, 'parameters can set any object';

    $meta->set_returns($obj);
    is $meta->returns, $obj, 'return can set any object';
};


done_testing;
