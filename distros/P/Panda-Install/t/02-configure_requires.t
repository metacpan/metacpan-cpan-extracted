use 5.012;
use warnings;
use Test::More;
use Panda::Install;

chdir 't/testmod' or die $!;

my %args;

# Panda::Install is added to CONFIGURE_REQUIRES
%args = Panda::Install::makemaker_args(NAME => 'TestMod');
ok(exists $args{CONFIGURE_REQUIRES}{'Panda::Install'});

done_testing();