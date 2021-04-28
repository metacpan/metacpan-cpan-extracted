use Test2::V0;

use Sub::Meta::Param;
use Sub::Meta::Test qw(sub_meta_param);

subtest 'Fail: invalid type' => sub {
    my $events = intercept {
        my $meta = Sub::Meta::Param->new('Str');
        is $meta, sub_meta_param({
            type => 'Int',
        });
    };

    is $events, array {
        event 'Fail';
        end;
    };

    my ($fail) = @$events;
    my $table = $fail->info->[0]{table};

    is $table->{rows}, [
        [ 'type()',   D(), 'Str', 'eq', 'Int', D() ],
        [ 'isa_()',   D(), 'Str', 'eq', 'Int', D() ],
    ];
};

subtest 'Fail: invalid etc' => sub {
    my $events = intercept {
        my $meta = Sub::Meta::Param->new;
        is $meta, sub_meta_param({
            name     => 'hello',
            default  => 1,
            coerce   => 1,
            optional => 1,
            named    => 1,
            invocant => 1,
        });
    };

    is $events, array {
        event 'Fail';
        end;
    };

    my ($fail) = @$events;
    my $table = $fail->info->[0]{table};

    is $table->{rows}, [
        [ 'name()',        D(), '', 'eq', D(), D() ],
        [ 'default()',     D(), '<UNDEF>', '', D(), D() ],
        [ 'coerce()',      D(), '<UNDEF>', '', D(), D() ],
        [ 'optional()',    D(), !!0, 'eq', !!1, D() ],
        [ 'required()',    D(), !!1, 'eq', !!0, D() ],
        [ 'named()',       D(), !!0, 'eq', !!1, D() ],
        [ 'positional()',  D(), !!1, 'eq', !!0, D() ],
        [ 'invocant()',    D(), !!0, 'eq', !!1, D() ],
        [ 'has_name()',    D(), '', 'eq', !!1, D() ],
        [ 'has_default()', D(), '', 'eq', !!1, D() ],
        [ 'has_coerce()',  D(), '', 'eq', !!1, D() ],
    ];
};

done_testing;
