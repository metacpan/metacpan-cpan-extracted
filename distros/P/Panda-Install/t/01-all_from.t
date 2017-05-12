use 5.012;
use warnings;
use Test::More;
use Panda::Install;

chdir 't/testmod' or die $!;

my %args;

# ALL_FROM defaults to NAME
%args = Panda::Install::makemaker_args(NAME => 'TestMod');
is($args{NAME}, 'TestMod');
is($args{VERSION_FROM}, 'lib/TestMod.pm');
is($args{ABSTRACT_FROM}, 'lib/TestMod.pm');

# ALL_FROM can override NAME
%args = Panda::Install::makemaker_args(NAME => 'TestMod', ALL_FROM => 'lib/Suka.pm');
is($args{NAME}, 'TestMod');
is($args{VERSION_FROM}, 'lib/Suka.pm');
is($args{ABSTRACT_FROM}, 'lib/Suka.pm');

done_testing();