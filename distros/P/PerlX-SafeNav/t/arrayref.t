use Test2::V0;
use PerlX::SafeNav ('$safenav', '$unsafenav');

package O {
    sub a { $_[0]->{a} }
};

subtest "perl native", sub {
    my $foo = [];
    my $ret = 42;
    ok lives {
        $ret = $foo->[0][1][2][3];
    };
    is $ret, U();
};

subtest 'with $savenav', sub {
    my $foo = [];
    my $ret = 42;
    ok lives {
        $ret = $foo->$safenav->[0][1][2][3]->$unsafenav;
    };
    is $ret, U();
};

subtest 'a mix chain with method calls and array fetches', sub {
    my $o = bless {
        a => [undef, undef],
    }, 'O';
    $o->{a}[1] = $o;

    my $ret = 42;
    ok dies {
        $ret = $o->a()->[0]->a();
    };
    is $ret, 42;

    $ret = 42;
    ok lives {
        $ret = $o->a()->[1]->a()->[0];
    };
    is $ret, U();

    $ret = 42;
    ok lives {
        $ret = $o->$safenav->a()->[0]->a()->$unsafenav;
    };
    is $ret, undef;

    $ret = 42;
    ok lives {
        $ret = $o->$safenav->a()->[2]->a()->$unsafenav;
    };
    is $ret, undef;
};

done_testing;
