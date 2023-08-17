use Test2::V0;
use PerlX::SafeNav ('$safenav', '$unsafenav');

package O {
    sub a { $_[0]->{a} }
};

subtest 'a mix chain with method calls, array fetches, and hash fetches', sub {
    my $o = bless {
        a => [undef, undef],
        h => {},
    }, 'O';
    $o->{a}[1] = $o;
    $o->{h}{o} = $o;

    my $ret;
    ok dies { $ret = $o->a()->[0]->a() };

    $ret = 42;
    ok lives { $ret = $o->$safenav->a()->[0]->a()->$unsafenav };
    is $ret, U();

    ok dies { $ret = $o->{h}->{p}->[0]->f() };
    $ret = 42;
    ok lives { $ret = $o->$safenav->{h}->{p}->[0]->f()->$unsafenav };
    is $ret, U();
};

done_testing;
