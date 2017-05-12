use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Install;

chdir 't/testmod_noxs' or die $!;

my %args;

%args = Panda::Install::makemaker_args(NAME => 'TestMod');
is($args{H}, undef);
is($args{C}, undef);
is($args{XS}, undef);
is($args{CCFLAGS}, undef);
is($args{LDFROM}, undef);

done_testing();
