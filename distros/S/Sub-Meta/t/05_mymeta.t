use Test2::V0;
use lib 't/lib';

use MySubMeta;

my $meta = MySubMeta->new(
    subname => 'hello',
    args    => ['Str'],
    returns => 'Str',
);

isa_ok $meta,             ('MySubMeta',             'Sub::Meta');
isa_ok $meta->parameters, ('MySubMeta::Parameters', 'Sub::Meta::Parameters');
isa_ok $meta->returns,    ('MySubMeta::Returns',    'Sub::Meta::Returns');
isa_ok $meta->args->[0],  ('MySubMeta::Param',      'Sub::Meta::Param');

is $meta->subname, 'hello';
is $meta->parameters, MySubMeta::Parameters->new(args => ['Str']);
is $meta->returns, MySubMeta::Returns->new('Str');

done_testing;
