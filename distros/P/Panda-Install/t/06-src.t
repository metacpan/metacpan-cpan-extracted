use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Install;

chdir 't/testmod' or die $!;

my %args;

# add folder's content
%args = Panda::Install::makemaker_args(NAME => 'TestMod', SRC => 'src2');
cmp_bag($args{H}, [qw{file1.h file2.hh prog1.hxx prog2.hpp src2/s2.h}]);
cmp_bag($args{C}, [qw{file1.c file2.cc prog1.cxx prog2.cpp src2/s2.cc src2/s2.c misc.c my.c test.c}]);
cmp_deeply($args{XS}, {'my.xs' => 'my.c', 'misc.xs' => 'misc.c', 'test.xs' => 'test.c', 'src2/s2.xs' => 'src2/s2.c'});

%args = Panda::Install::makemaker_args(NAME => 'TestMod', SRC => ['src', 'src2']);
cmp_bag($args{H}, [qw{file1.h file2.hh prog1.hxx prog2.hpp src2/s2.h src/sfile1.h src/sfile2.h}]);
cmp_bag($args{C}, [qw{file1.c file2.cc prog1.cxx prog2.cpp src2/s2.cc src2/s2.c misc.c my.c test.c src/sfile1.cc src/sfile2.cc}]);
cmp_deeply($args{XS}, {'my.xs' => 'my.c', 'misc.xs' => 'misc.c', 'test.xs' => 'test.c', 'src2/s2.xs' => 'src2/s2.c'});

# only folder's content (remove all defaults)
%args = Panda::Install::makemaker_args(NAME => 'TestMod', H => [], XS => {}, C => [], SRC => ['src', 'src2']);
cmp_bag($args{H}, [qw{src2/s2.h src/sfile1.h src/sfile2.h}]);
cmp_bag($args{C}, [qw{src2/s2.cc src2/s2.c src/sfile1.cc src/sfile2.cc}]);
cmp_deeply($args{XS}, {'src2/s2.xs' => 'src2/s2.c'});

done_testing();