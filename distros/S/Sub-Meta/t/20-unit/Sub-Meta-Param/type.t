use Test2::V0;

use Sub::Meta::Param;
use Sub::Meta::Test qw(sub_meta_param);

my $param = Sub::Meta::Param->new;

subtest 'set Str' => sub {
    is $param->set_type('Str'), $param;
    is $param, sub_meta_param({ type => 'Str' });
};

subtest 'set blessed' => sub {
    my $Str = bless {}, 'Str';
    is $param->set_type($Str), $param;
    is $param, sub_meta_param({ type => $Str });
};

subtest 'set coderef' => sub {
    my $Str = sub { };
    is $param->set_type($Str), $param;
    is $param, sub_meta_param({ type => $Str });
};

subtest 'set undef' => sub {
    is $param->set_type(undef), $param;
    is $param, sub_meta_param({ type => undef });
};

done_testing;
