use Test2::V0;
use PerlX::SafeNav ('$safenav', '$unsafenav');

subtest 'safenav on an unblessed arrayref', sub {
    my $o = ['foo', 'bar', 'baz'];

    subtest 'without safenav, it dies', sub {
        my $orig = my $ret = \42;
        ok dies {
            $ret = $o->[1]->[3]->[5];
        }, 'without safenav, this statement dies for it tries to treat "bar" as a arrayref';

        is $ret, $orig;
    };

    subtest 'with safenav, it still dies.', sub {
        my $orig = my $ret = \42;
        ok dies {
            $ret = $o->$safenav->[1]->[3]->[5]->$unsafenav;
        }, 'even with safenav this statement still ties becaues safenav should not rescure cases of derefing a scalar';
        is $ret, $orig;
    };
};

done_testing;
