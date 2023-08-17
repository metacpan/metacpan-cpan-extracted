use Test2::V0;
use PerlX::SafeNav ('$safenav', '$unsafenav');

package O {
    sub a { $_[0]->{a} }
};

subtest "perl native", sub {
    my $foo = {};
    my $ret = 42;
    ok lives {
        $ret = $foo->{a}{b}{c}{d};
    };
    is $ret, U();
};

subtest 'with $savenav', sub {
    my $foo = {};
    my $ret = 42;
    ok lives {
        $ret = $foo->$safenav->{a}{b}{c}{d}->$unsafenav;
    };
    is $ret, U();
};

subtest 'a mix chain with method calls and hash fetches', sub {
    my $o = bless {
        a => { o => undef, p => undef },
    }, 'O';
    $o->{a}{o} = $o;

    my $ret = 42;
    ok dies {
        $ret = $o->a()->{p}->a();
    };
    is $ret, 42;

    $ret = 42;
    ok lives {
        $ret = $o->a()->{o}->a();
    };
    is $ret, D();

    $ret = 42;
    ok lives {
        $ret = $o->$safenav->a()->{p}->a()->$unsafenav;
    }, 'fetching a key mapping to undef';
    is $ret, undef;

    $ret = 42;
    ok lives {
        $ret = $o->$safenav->a()->{q}->a()->$unsafenav;
    }, 'fetch a non-existing key';
    is $ret, undef;
};

done_testing;
