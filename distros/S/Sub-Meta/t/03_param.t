use Test2::V0;

use Sub::Meta::Param;

subtest 'single arg' => sub {
    my $param = Sub::Meta::Param->new('Type');
    is $param->type, 'Type', 'type';
    is $param->name, undef, 'name';
    is $param->default, undef, 'default';
    is $param->coerce, undef, 'coerce';
    ok $param->positional, 'positional';
    ok !$param->named, 'named';
    ok $param->required, 'required';
    ok !$param->optional, 'optional';
};

subtest 'hashref arg' => sub {
    my $param = Sub::Meta::Param->new({ type => 'Type', name => 'foo', named => 1, optional => 1, default => 999 });
    is $param->type, 'Type', 'type';
    is $param->name, 'foo', 'name';
    is $param->default, 999, 'default';
    is $param->coerce, undef, 'coerce';
    ok !$param->positional, 'positional';
    ok $param->named, 'named';
    ok !$param->required, 'required';
    ok $param->optional, 'optional';
};

subtest 'setter' => sub {
    my $param = Sub::Meta::Param->new;

    is $param->set_name('$foo'), $param, 'set_name';
    is $param->name, '$foo', 'name';
    is $param->set_type('Type'), $param, 'set_type';
    is $param->type, 'Type', 'type';
    is $param->set_default('Default'), $param, 'set_default';
    is $param->default, 'Default', 'default';
    is $param->set_coerce('Coerce'), $param, 'set_coerce';
    is $param->coerce, 'Coerce', 'coerce';

    is $param->set_optional, $param, 'set_optional';
    ok $param->optional, 'optional';
    is $param->set_optional(0), $param, 'set_optional';
    ok !$param->optional, 'optional';

    is $param->set_required, $param, 'set_required';
    ok $param->required, 'required';
    is $param->set_required(0), $param, 'set_required';
    ok !$param->required, 'required';

    is $param->set_positional, $param, 'set_positional';
    ok $param->positional, 'positional';
    is $param->set_positional(0), $param, 'set_positional';
    ok !$param->positional, 'positional';

    is $param->set_named, $param, 'set_named';
    ok $param->named, 'named';
    is $param->set_named(0), $param, 'set_named';
    ok !$param->named, 'named';
};

subtest 'overload' => sub {
    my $param = Sub::Meta::Param->new({ name => '$foo' });
    is "$param", '$foo', 'overload string';

    my $empty = Sub::Meta::Param->new({ });
    is "$empty", '', 'overload no string';
};

subtest 'new' => sub {
    is(Sub::Meta::Param->new(name => '$foo')->name, '$foo', 'args list');

    is(Sub::Meta::Param->new([])->type, [], 'args NOT HASH');

    ok(Sub::Meta::Param->new(required => 0)->optional, 'args required');
    ok(Sub::Meta::Param->new(positional => 0)->named, 'args positional');
};

done_testing;
