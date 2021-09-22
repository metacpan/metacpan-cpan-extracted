use Test2::V0;
use lib 't/lib';

use Sub::Meta::CreatorFunction;

sub hello {}

subtest 'customize find_submeta' => sub {
    local @Sub::Meta::CreatorFunction::FINDER_CLASSES = qw(MySubMeta::Finder);
    my $meta = Sub::Meta::CreatorFunction::find_submeta(\&hello);
    isa_ok $meta, 'Sub::Meta';
    is $meta->sub, undef;
    isnt $meta->sub, \&hello;
};

subtest 'cannot customize / because state' => sub {
    local @Sub::Meta::CreatorFunction::FINDER_CLASSES = qw(Sub::Meta::Finder::Default);
    my $meta = Sub::Meta::CreatorFunction::find_submeta(\&hello);
    isa_ok $meta, 'Sub::Meta';
    is $meta->sub, undef;
    isnt $meta->sub, \&hello;
};

done_testing;
