use Test2::V0;

use Sub::Meta::Parameters;
use Sub::Meta::Test qw(sub_meta_parameters);

subtest 'Fail: invalid args' => sub {
    my $events = intercept {
        my $meta = Sub::Meta::Parameters->new(args => []);
        is $meta, sub_meta_parameters({
            args => ['Int'],
        });
    };

    is $events, array {
        event 'Fail';
        end;
    };

    my ($fail) = @$events;
    my $table = $fail->info->[0]{table};

    is $table->{rows}, [
        [ 'args()->[0]',   D(), '<DOES NOT EXIST>', '', 'Int', D() ],
    ];
};


subtest 'Fail: invalid etc' => sub {
    my $events = intercept {
        my $meta = Sub::Meta::Parameters->new(args => []);
        is $meta, sub_meta_parameters({
            nshift                   => 1,
            slurpy                   => 1,
            all_args                 => ['hello'],
            _all_positional_required => ['hello'],
            positional               => ['hello'],
            positional_required      => ['hello'],
            positional_optional      => ['hello'],
            named                    => ['hello'],
            named_required           => ['hello'],
            named_optional           => ['hello'],
            invocant                 => 'hello',
            invocants                => ['hello'],
            args_min                 => 1,
            args_max                 => 100,
        });
    };

    is $events, array {
        event 'Fail';
        end;
    };

    my ($fail) = @$events;
    my $table = $fail->info->[0]{table};

    is $table->{rows}, [
        [ 'nshift()',                        D(), '0', 'eq', 1, D() ],
        [ 'slurpy()',                        D(), '<UNDEF>', '', 1, D() ],
        [ 'all_args()->[0]',                 D(), '<DOES NOT EXIST>', '', D(), D() ],
        [ '_all_positional_required()->[0]', D(), '<DOES NOT EXIST>', '', D(), D() ],
        [ 'positional()->[0]',               D(), '<DOES NOT EXIST>', '', D(), D() ],
        [ 'positional_required()->[0]',      D(), '<DOES NOT EXIST>', '', D(), D() ],
        [ 'positional_optional()->[0]',      D(), '<DOES NOT EXIST>', '', D(), D() ],
        [ 'named()->[0]',                    D(), '<DOES NOT EXIST>', '', D(), D() ],
        [ 'named_required()->[0]',           D(), '<DOES NOT EXIST>', '', D(), D() ],
        [ 'named_optional()->[0]',           D(), '<DOES NOT EXIST>', '', D(), D() ],
        [ 'invocant()',                      D(), '<UNDEF>', '', D(), D() ],
        [ 'invocants()->[0]',                D(), '<DOES NOT EXIST>', '', D(), D() ],
        [ 'args_min()',                      D(), '0', 'eq', 1, D() ],
        [ 'args_max()',                      D(), '0', 'eq', 100, D() ],
        [ 'has_args()',                      D(), !!1, 'eq', '', D() ],
        [ 'has_slurpy()',                    D(), '', 'eq', !!1, D() ],
        [ 'has_invocant()',                  D(), '', 'eq', !!1, D() ],
    ];
};

done_testing;
