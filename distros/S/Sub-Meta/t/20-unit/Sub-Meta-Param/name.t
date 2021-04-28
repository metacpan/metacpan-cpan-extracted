use Test2::V0;

use Sub::Meta::Param;
use Sub::Meta::Test qw(sub_meta_param);

my $param = Sub::Meta::Param->new;

subtest 'set $foo' => sub {
    is $param->set_name('$foo'), $param;
    is $param, sub_meta_param({ name => '$foo' });
};

subtest 'set foo' => sub {
    is $param->set_name('bar'), $param;
    is $param, sub_meta_param({ name => 'bar' });
};

subtest 'set undef' => sub {
    is $param->set_name(undef), $param;
    is $param, sub_meta_param({ name => '' });
};

done_testing;
