use strict;
use warnings;

use Test::More;

use ObjectDB::Util 'merge_rows';

subtest 'not merge when different columns' => sub {
    my $merged = merge_rows([ { foo => 'bar' }, { bar => 'baz' } ]);

    is_deeply($merged, [ { foo => 'bar' }, { bar => 'baz' } ]);
};

subtest 'not merge when different undefined values' => sub {
    my $merged = merge_rows([ { foo => 'bar' }, { foo => undef } ]);

    is_deeply($merged, [ { foo => 'bar' }, { foo => undef } ]);
};

subtest 'not merge when different values' => sub {
    my $merged = merge_rows([ { foo => 'bar' }, { foo => 'baz' } ]);

    is_deeply($merged, [ { foo => 'bar' }, { foo => 'baz' } ]);
};

subtest 'merge when same keys and values' => sub {
    my $merged = merge_rows([ { foo => 'bar' }, { foo => 'bar' } ]);

    is_deeply($merged, [ { foo => 'bar' } ]);
};

subtest 'not merge when different joins' => sub {
    my $merged = merge_rows([ { foo => 'bar', join1 => {} }, { foo => 'bar', join2 => {} } ]);

    is_deeply($merged, [ { foo => 'bar', join1 => {} }, { foo => 'bar', join2 => {} } ]);
};

subtest 'merge same joins' => sub {
    my $merged =
      merge_rows([ { foo => 'bar', join => { hi => 'there' } }, { foo => 'bar', join => { hi => 'there' } } ]);

    is_deeply($merged, [ { foo => 'bar', join => { hi => 'there' } } ]);
};

subtest 'merge different joins' => sub {
    my $merged =
      merge_rows([ { foo => 'bar', join => { hi => 'here' } }, { foo => 'bar', join => { hi => 'there' } } ]);

    is_deeply($merged, [ { foo => 'bar', join => [ { hi => 'here' }, { hi => 'there' } ] } ]);
};

subtest 'merge different joins several times' => sub {
    my $merged = merge_rows(
        [
            { foo => 'bar', join => { hi => 'here' } },
            { foo => 'bar', join => { hi => 'there' } },
            { foo => 'bar', join => { hi => 'everywhere' } }
        ]
    );

    is_deeply(
        $merged,
        [
            {
                foo  => 'bar',
                join => [ { hi => 'here' }, { hi => 'there' }, { hi => 'everywhere' } ]
            }
        ]
    );
};

subtest 'merge rows that do not follow each other' => sub {
    my $merged = merge_rows(
        [
            { foo => 'bar', join => { hi => 'here' } },
            { foo => 'baz', join => { hi => 'there' } },
            { foo => 'bar', join => { hi => 'everywhere' } }
        ]
    );

    is_deeply(
        $merged,
        [
            {
                foo  => 'bar',
                join => [ { hi => 'here' }, { hi => 'everywhere' } ]
            },
            {
                foo  => 'baz',
                join => { hi => 'there' }
            }
        ]
    );
};

done_testing;
