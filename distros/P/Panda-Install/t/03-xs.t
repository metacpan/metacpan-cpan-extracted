use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Install;

chdir 't/testmod' or die $!;

my %args;

# defaults (without SRC dir) are all xs in root folder
%args = Panda::Install::makemaker_args(NAME => 'TestMod');
cmp_deeply($args{XS}, {'test.xs' => 'test.c', 'my.xs' => 'my.c', 'misc.xs' => 'misc.c'});

# replace defaults
%args = Panda::Install::makemaker_args(NAME => 'TestMod', XS => 'm*.xs');
cmp_deeply($args{XS}, {'my.xs' => 'my.c', 'misc.xs' => 'misc.c'});

%args = Panda::Install::makemaker_args(NAME => 'TestMod', XS => 'test.xs misc.xs');
cmp_deeply($args{XS}, {'test.xs' => 'test.c', 'misc.xs' => 'misc.c'});

%args = Panda::Install::makemaker_args(NAME => 'TestMod', XS => ['test.xs', 'my.xs']);
cmp_deeply($args{XS}, {'test.xs' => 'test.c', 'my.xs' => 'my.c'});

%args = Panda::Install::makemaker_args(NAME => 'TestMod', XS => ['test.xs', 'my.xs m*.xs']);
cmp_deeply($args{XS}, {'test.xs' => 'test.c', 'my.xs' => 'my.c', 'misc.xs' => 'misc.c'});

# makemaker's style
%args = Panda::Install::makemaker_args(NAME => 'TestMod', XS => {'misc.xs' => 'jopa.c'});
cmp_deeply($args{XS}, {'misc.xs' => 'jopa.c'});

done_testing();