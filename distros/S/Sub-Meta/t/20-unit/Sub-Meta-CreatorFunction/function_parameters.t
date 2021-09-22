use Test2::V0;
use Test2::Require::Module 'Function::Parameters', '2.000003';

use Sub::Meta::CreatorFunction;

use Types::Standard -types;
use Function::Parameters;

fun hello(Int $a) { }

my $meta = Sub::Meta::CreatorFunction::find_submeta(\&hello);
isa_ok $meta , 'Sub::Meta';
is $meta->args->[0]->type, 'Int';
is $meta->args->[0]->name, '$a';

done_testing;
