use Test2::V0;

use Sub::Meta::Param;
use Sub::Meta::Test qw(sub_meta_param);

my $param = Sub::Meta::Param->new;

subtest 'set default' => sub {
    is $param->set_default('hoge'), $param;
    is $param, sub_meta_param({ default => 'hoge' });
};

subtest 'set blessed' => sub {
    my $default = bless {}, 'Default';
    is $param->set_default($default), $param;
    is $param, sub_meta_param({ default => $default });
};

subtest 'set coderef' => sub {
    my $default = sub { 999 };
    is $param->set_default($default), $param;
    is $param, sub_meta_param({ default => $default });
};

subtest 'set undef' => sub {
    is $param->set_default(undef), $param;
    is $param, sub_meta_param({ default => undef });
};

done_testing;
