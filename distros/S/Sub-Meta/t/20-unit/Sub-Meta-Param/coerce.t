use Test2::V0;

use Sub::Meta::Param;
use Sub::Meta::Test qw(sub_meta_param);

my $param = Sub::Meta::Param->new;

subtest 'set coerce' => sub {
    is $param->set_coerce('hoge'), $param;
    is $param, sub_meta_param({ coerce => 'hoge' });
};

subtest 'set blessed' => sub {
    my $coerce = bless {}, 'Default';
    is $param->set_coerce($coerce), $param;
    is $param, sub_meta_param({ coerce => $coerce });
};

subtest 'set coderef' => sub {
    my $coerce = sub { 999 };
    is $param->set_coerce($coerce), $param;
    is $param, sub_meta_param({ coerce => $coerce });
};

subtest 'set undef' => sub {
    is $param->set_coerce(undef), $param;
    is $param, sub_meta_param({ coerce => undef });
};

done_testing;
