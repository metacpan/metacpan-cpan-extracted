use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

opt bool => (
    isa     => 'Bool',
    comment => 'comment',
);

opt str => (
    isa     => 'Str',
    comment => 'comment',
);

opt int => (
    isa     => 'Int',
    comment => 'comment',
);

opt num => (
    isa     => 'Num',
    comment => 'comment',
);

opt arrayref => (
    isa     => 'ArrayRef',
    comment => 'comment',
);

opt hashref => (
    isa     => 'HashRef',
    comment => 'comment',
);

@ARGV = ();
is_deeply optargs, {}, 'nothing';

@ARGV = (qw/--bool/);
is_deeply optargs, { bool => 1 }, 'got a bool';

is_deeply optargs(qw/--no-bool/), { bool => 0 }, 'manual argv got no bool';

@ARGV = qw(--int=3);
is optargs->{int}, 3,     'int val';
is optargs->{str}, undef, 'undef Str still';

@ARGV = qw(--num=3.14);
is optargs->{num}, 3.14, 'num val';

@ARGV = qw(--num=14 --bool --str something);
my $opts = optargs;
is $opts->{num}, 14, 'num val';
ok $opts->{bool}, 'bool ok';
is $opts->{str}, 'something', 'str something';

@ARGV = qw(--arrayref=14);
is_deeply optargs->{arrayref}, [14], 'arrayref single';

@ARGV = qw(--arrayref=14 --arrayref=15);
is_deeply optargs->{arrayref}, [ 14, 15 ], 'arrayref multi';

@ARGV = qw(--arrayref=15 --arrayref=14);
is_deeply optargs->{arrayref}, [ 15, 14 ], 'arrayref multi order';

@ARGV = qw(--hashref one=1 --hashref two=2);
is_deeply optargs->{hashref}, { one => 1, two => 2 }, 'hashref multi';

arg argstr => (
    isa     => 'Str',
    comment => 'comment',
);

arg argint => (
    isa     => 'Int',
    comment => 'comment',
);

arg argnum => (
    isa     => 'Num',
    comment => 'comment',
);

arg argarrayref => (
    isa     => 'ArrayRef',
    comment => 'comment',
);

arg arghashref => (
    isa     => 'HashRef',
    comment => 'comment',
);

@ARGV = (qw/x/);
is_deeply optargs, { argstr => 'x' }, 'got a str';

is_deeply optargs(qw/y/), { argstr => 'y' }, 'manual argv got str';

@ARGV = (qw/k 1/);
is_deeply optargs, { argint => 1, argstr => 'k' }, 'str reset on new arg';

@ARGV = (qw/k 1 3.14 1 one=1/);

is_deeply optargs,
  {
    argstr      => 'k',
    argint      => 1,
    argnum      => 3.14,
    argarrayref => [1],
    arghashref  => { one => 1 },
  },
  'deep match';

done_testing;
