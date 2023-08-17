use Test2::V0;
use PerlX::SafeNav ('$safenav', '$unsafenav');

package O {
    sub a { $_[0]->{a} }
    sub b { $_[0]->{b} }
    sub c { $_[0]->{c} }
};

subtest 'synopsis', sub {
    my $o = bless {}, 'O';

    my $ret = 42;
    ok lives {
        $ret = $o->$safenav->a()->b()->c()->$unsafenav;
    };
    is $ret, U();

    $ret = 42;
    $o->{a} = $o;
    ok lives {
        $ret = $o->$safenav->a()->b()->c()->$unsafenav;
    };
    is $ret, U();

    $ret = 42;
    $o->{b} = $o;
    ok lives {
        $ret = $o->$safenav->a()->b()->c()->$unsafenav;
    };
    is $ret, U();

    $ret = 42;
    $o->{c} = my $final = rand();
    ok lives {
        $ret = $o->$safenav->a()->b()->c()->$unsafenav;
    };
    is $ret, $final;
};

done_testing;
