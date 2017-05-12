use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

opt long_str => (
    isa     => 'Str',
    alias   => 's',
    comment => 'comment',
);

@ARGV = (qw/--long-str x/);
is_deeply optargs, { long_str => 'x' }, 'dashed';

@ARGV = (qw/--long_str x/);
is_deeply optargs, { long_str => 'x' }, 'fullname';

@ARGV = (qw/-s x/);
is_deeply optargs, { long_str => 'x' }, 'alias';

done_testing;
