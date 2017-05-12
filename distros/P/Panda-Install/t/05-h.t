use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Install;

chdir 't/testmod' or die $!;

my %args;

# defaults (without SRC dir) are all h files in root folder
%args = Panda::Install::makemaker_args(NAME => 'TestMod');
cmp_bag($args{H}, [qw/file1.h file2.hh prog1.hxx prog2.hpp/]);

# no h files
%args = Panda::Install::makemaker_args(NAME => 'TestMod', H => []);
cmp_bag($args{H}, []);

# custom h files
%args = Panda::Install::makemaker_args(NAME => 'TestMod', H => 'src/*.h file2.hh');
cmp_bag($args{H}, [qw{src/sfile1.h src/sfile2.h file2.hh}]);

done_testing();