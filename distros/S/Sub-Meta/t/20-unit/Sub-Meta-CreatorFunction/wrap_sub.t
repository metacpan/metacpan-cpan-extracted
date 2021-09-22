use Test2::V0;
use Test2::Require::Module 'Sub::WrapInType', '0.04';

use Sub::Meta::CreatorFunction;

use Types::Standard -types;
use Sub::WrapInType;

my $sub = wrap_sub([Int] => Str, sub {});

my $meta = Sub::Meta::CreatorFunction::find_submeta($sub);
isa_ok $meta , 'Sub::Meta';
is $meta->args->[0]->type, 'Int';
is $meta->returns->scalar, 'Str';

done_testing;
