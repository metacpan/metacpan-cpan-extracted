use Test2::V0;

use Sub::Meta::Param;

my $param1 = Sub::Meta::Param->new({ name => '$foo' });
my $param2 = Sub::Meta::Param->new({ name => '$bar' });
my $param3 = Sub::Meta::Param->new({ name => '$foo' });

ok $param1 eq $param1;
ok $param1 ne $param2;
ok $param1 eq $param3;

done_testing;
