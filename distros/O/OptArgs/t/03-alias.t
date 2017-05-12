use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

opt str => (
    isa     => 'Str',
    alias   => 's',
    comment => 'comment',
);

@ARGV = (qw/--str x/);
is_deeply optargs, { str => 'x' }, 'fullname';

@ARGV = (qw/-s x/);
is_deeply optargs, { str => 'x' }, 'alias';

done_testing;
