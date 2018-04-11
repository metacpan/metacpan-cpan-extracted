use strict;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Install;

chdir 't/testmod' or die $!;

my %args;

# CPLUS changes compiler to C++
%args = Panda::Install::makemaker_args(NAME => 'TestMod', CPLUS => 1);
is($args{CC}, 'c++');
is($args{LD}, '$(CC)');
is($args{XSOPT}, '-C++');
unlike($args{CCFLAGS}, qr/-std=c\+\+/);

# CPLUS doesn't change custom values
%args = Panda::Install::makemaker_args(NAME => 'TestMod', CPLUS => 1, CC => 'mycc', XSOPT => 'jopanah');
is($args{CC}, 'mycc');
is($args{LD}, '$(CC)');
is($args{XSOPT}, 'jopanah -C++');

# CPLUS version set
%args = Panda::Install::makemaker_args(NAME => 'TestMod', CPLUS => 11);
like($args{CCFLAGS}, qr/-std=c\+\+11/);

done_testing();