use strict;
use warnings;
use Test::More;
use OptArgs;

my $str = 1;
opt subref => (
    isa     => 'Str',
    default => sub {
        my $ref = shift;
        is $ref->{str}, $str, "str is $str";
        return 2;
    },
    comment => 'do nothing',
);

opt str => (
    isa     => 'Str',
    default => 1,
    comment => 'do nothing',
);

is_deeply optargs, { subref => 2, str => $str }, 'subref and normal default';

@ARGV = (qw/--str 4/);
$str  = 4;
is_deeply optargs, { subref => 2, str => 4 }, 'normal not default';

@ARGV = (qw/--subref 3/);
$str  = 1;
is_deeply optargs, { subref => 3, str => 1 }, 'subref not def';

arg defarg => (
    isa     => 'Str',
    default => sub {
        my $ref = shift;
        pass 'default subref called';
        return 2;
    },
    comment => 'do nothing',
);

is_deeply optargs, { str => 1, defarg => 2, subref => 2 },
  'subref and normal default';

@ARGV = (qw/1/);
is_deeply optargs, { str => 1, defarg => 1, subref => 2 },
  'subref and not default';

done_testing();
