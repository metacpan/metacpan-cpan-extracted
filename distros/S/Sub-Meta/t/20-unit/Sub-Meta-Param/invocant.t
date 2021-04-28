use Test2::V0;

use Sub::Meta::Param;
use Sub::Meta::Test qw(sub_meta_param);

my $param = Sub::Meta::Param->new;

subtest 'set invocant' => sub {
    is $param->set_invocant('hoge'), $param;
    is $param, sub_meta_param({ invocant => !!1 });
};

subtest 'set 1' => sub {
    is $param->set_invocant(1), $param;
    is $param, sub_meta_param({ invocant => !!1 });
};

subtest 'set 0' => sub {
    is $param->set_invocant(0), $param;
    is $param, sub_meta_param({ invocant => !!0 });
};

subtest 'set empty string' => sub {
    is $param->set_invocant(''), $param;
    is $param, sub_meta_param({ invocant => !!0 });
};

subtest 'set undef, then TRUE' => sub {
    is $param->set_invocant(undef), $param;
    is $param, sub_meta_param({ invocant => !!1 });
};

subtest 'set invocant / no args' => sub {
    is $param->set_invocant, $param;
    is $param, sub_meta_param({ invocant => !!1 });
};

done_testing;
