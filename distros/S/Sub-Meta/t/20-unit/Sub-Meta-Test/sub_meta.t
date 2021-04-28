use Test2::V0;

use Sub::Meta;
use Sub::Meta::Test qw(sub_meta);

subtest 'Fail: invalid subname' => sub {
    my $events = intercept {
        my $meta = Sub::Meta->new;
        is $meta, sub_meta({
            subname => 'hoge',
        });
    };

    is $events, array {
        event 'Fail';
        end;
    };

    my ($fail) = @$events;
    my $table = $fail->info->[0]{table};

    is $table->{rows}, [
        [ 'subname()',     D(), '', 'eq', 'hoge', D() ],
        [ 'has_subname()', D(), '', 'eq', !!1, D() ],
    ];
};

subtest 'Fail: invalid etc' => sub {
    my $events = intercept {
        my $meta = Sub::Meta->new;
        is $meta, sub_meta({
            subname   => 'bar',
            stashname => 'Foo',
            file      => 'foo.t',
            line      => 999,
            prototype => '$$',
            attribute => ['method'],
            parameters => 'parameters',
            returns    => 'returns',
            is_constant => 1,
            is_method   => 1,
        });
    };

    is $events, array {
        event 'Fail';
        end;
    };

    my ($fail) = @$events;
    my $table = $fail->info->[0]{table};

    is $table->{rows}, [
        [ 'subname()',        D(), '', 'eq', 'bar', D() ],
        [ 'stashname()',      D(), '', 'eq', 'Foo', D() ],
        [ 'file()',           D(), '<UNDEF>', '', 'foo.t', D() ],
        [ 'line()',           D(), '<UNDEF>', '', 999, D() ],
        [ 'prototype()',      D(), '<UNDEF>', '', '$$', D() ],
        [ 'attribute()',      D(), '<UNDEF>', '', D(), D() ],
        [ 'parameters()',     D(), '<UNDEF>', '', D(), D() ],
        [ 'returns()',        D(), '<UNDEF>', '', D(), D() ],
        [ 'is_constant()',    D(), !!0, 'eq', !!1, D() ],
        [ 'is_method()',      D(), !!0, 'eq', !!1, D() ],
        [ 'has_subname()',    D(), '', 'eq', !!1, D() ],
        [ 'has_stashname()',  D(), '', 'eq', !!1, D() ],
        [ 'has_file()',       D(), '', 'eq', !!1, D() ],
        [ 'has_line()',       D(), '', 'eq', !!1, D() ],
        [ 'has_prototype()',  D(), '', 'eq', !!1, D() ],
        [ 'has_attribute()',  D(), '', 'eq', !!1, D() ],
        [ 'has_parameters()', D(), '', 'eq', !!1, D() ],
        [ 'has_returns()',    D(), '', 'eq', !!1, D() ],
    ];
};

done_testing;
