use Test2::V0;

use Sub::Meta::Param;
use Sub::Meta::Test qw(sub_meta_param);

subtest 'set_optional' => sub {
    my $param = Sub::Meta::Param->new;

    subtest 'set optional' => sub {
        is $param->set_optional('hoge'), $param;
        is $param, sub_meta_param({ optional => !!1 });
    };

    subtest 'set 1' => sub {
        is $param->set_optional(1), $param;
        is $param, sub_meta_param({ optional => !!1 });
    };

    subtest 'set 0' => sub {
        is $param->set_optional(0), $param;
        is $param, sub_meta_param({ optional => !!0 });
    };

    subtest 'set empty string' => sub {
        is $param->set_optional(''), $param;
        is $param, sub_meta_param({ optional => !!0 });
    };

    subtest 'set undef, then TRUE' => sub {
        is $param->set_optional(undef), $param;
        is $param, sub_meta_param({ optional => !!1 });
    };

    subtest 'set optional / no args' => sub {
        is $param->set_optional, $param;
        is $param, sub_meta_param({ optional => !!1 });
    };
};

subtest 'set_required' => sub {
    my $param = Sub::Meta::Param->new;

    subtest 'set required' => sub {
        is $param->set_required('hoge'), $param;
        is $param->required, !!1;
        is $param, sub_meta_param({ optional => !!0 });
    };

    subtest 'set 1' => sub {
        is $param->set_required(1), $param;
        is $param->required, !!1;
        is $param, sub_meta_param({ optional => !!0 });
    };

    subtest 'set 0' => sub {
        is $param->set_required(0), $param;
        is $param->required, !!0;
        is $param, sub_meta_param({ optional => !!1 });
    };

    subtest 'set empty string' => sub {
        is $param->set_required(''), $param;
        is $param->required, !!0;
        is $param, sub_meta_param({ optional => !!1 });
    };

    subtest 'set undef, then TRUE' => sub {
        is $param->set_required(undef), $param;
        is $param->required, !!1;
        is $param, sub_meta_param({ optional => !!0 });
    };

    subtest 'set optional / no args' => sub {
        is $param->set_required, $param;
        is $param->required, !!1;
        is $param, sub_meta_param({ optional => !!0 });
    };
};

done_testing;
