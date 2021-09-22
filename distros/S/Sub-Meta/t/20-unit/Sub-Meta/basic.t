use Test2::V0;

use Sub::Meta;
use Sub::Meta::Test qw(sub_meta);

subtest 'no arguments meta' => sub {
    my $meta = Sub::Meta->new;
    is $meta, sub_meta();
};

subtest 'set_sub' => sub {
    sub hello($) :method {} ## no critic (ProhibitSubroutinePrototypes)
    my $meta = Sub::Meta->new;
    is $meta->set_sub(\&hello), $meta, 'set_sub';

    is $meta, sub_meta({
        sub         => \&hello,
        subname     => 'hello',
        stashname   => 'main',
        fullname    => 'main::hello',
        subinfo     => ['main', 'hello'],
        file        => __FILE__,
        line        => 12,
        prototype   => '$',
        attribute   => ['method'],
    });
};

subtest 'set_sub / anon sub' => sub {
    my $code = sub {};
    my $meta = Sub::Meta->new;
    is $meta->set_sub($code), $meta, 'set_sub';

    is $meta, sub_meta({
        sub         => $code,
        subname     => '',
        stashname   => 'main',
        fullname    => 'main::',
        subinfo     => ['main', undef],
        file        => __FILE__,
        line        => 30,
        attribute   => [],
    });
};

subtest 'set_fullname' => sub {
    my $meta = Sub::Meta->new;
    is $meta->set_fullname('Foo::Bar::baz'), $meta, 'set_fullname';

    is $meta, sub_meta({
        subname     => 'baz',
        stashname   => 'Foo::Bar',
        fullname    => 'Foo::Bar::baz',
        subinfo     => ['Foo::Bar', 'baz'],
    });
};

subtest 'set_stashname' => sub {
    my $meta = Sub::Meta->new;
    is $meta->set_stashname('Foo::Bar'), $meta, 'set_stashname';

    is $meta, sub_meta({
        subname     => '',
        stashname   => 'Foo::Bar',
        fullname    => 'Foo::Bar::',
        subinfo     => ['Foo::Bar'],
    });
};

subtest 'set_subinfo' => sub {
    my $meta = Sub::Meta->new;
    is $meta->set_subinfo(['A::B', 'c']), $meta, 'set_subinfo';

    is $meta, sub_meta({
        subname     => 'c',
        stashname   => 'A::B',
        fullname    => 'A::B::c',
        subinfo     => ['A::B', 'c'],
    });
};

subtest 'set_file' => sub {
    my $meta = Sub::Meta->new;
    is $meta->set_file('test/file.t'), $meta, 'set_file';

    is $meta, sub_meta({
        file => 'test/file.t',
    });
};

subtest 'set_line' => sub {
    my $meta = Sub::Meta->new;
    is $meta->set_line(999), $meta, 'set_line';

    is $meta, sub_meta({
        line => 999,
    });
};

subtest 'set_prototype' => sub {
    my $meta = Sub::Meta->new;
    is $meta->set_prototype('$;$'), $meta, 'set_prototype';

    is $meta, sub_meta({
        prototype => '$;$',
    });
};

subtest 'set_attribute' => sub {
    my $meta = Sub::Meta->new;
    is $meta->set_attribute(['foo','bar']), $meta, 'set_attribute';

    is $meta, sub_meta({
        attribute => ['foo','bar'],
    });
};

subtest 'set_parameters' => sub {
    my $parameters = Sub::Meta::Parameters->new(args => ['Int']);

    my $meta = Sub::Meta->new;
    is $meta->set_parameters($parameters), $meta, 'set_parameters';

    is $meta, sub_meta({
        parameters => $parameters,
    });
};

subtest 'set_returns' => sub {
    my $returns = Sub::Meta::Returns->new('Int');

    my $meta = Sub::Meta->new;
    is $meta->set_returns($returns), $meta, 'set_returns';

    is $meta, sub_meta({
        returns => $returns,
    });
};

subtest 'set_is_constant' => sub {
    my $meta = Sub::Meta->new;
    is $meta->set_is_constant(!!1), $meta, 'set_is_constant';

    is $meta, sub_meta({
        is_constant => !!1,
    });
};

subtest 'set_is_method' => sub {
    my $meta = Sub::Meta->new;
    is $meta->set_is_method(!!1), $meta, 'set_is_method';

    is $meta, sub_meta({
        is_method => !!1,
    });
};

done_testing;
