use Test2::V0;
use lib 't/lib';

use Sub::Meta::CreatorFunction;

sub hello {}

subtest 'not coderef' => sub {
    my $meta = Sub::Meta::CreatorFunction::find_submeta('hello');
    is $meta, undef;
};

subtest 'CodeRef' => sub {
    my $meta = Sub::Meta::CreatorFunction::find_submeta(\&hello);
    isa_ok $meta, 'Sub::Meta';
    is $meta->sub, \&hello;
    is $meta->args, [];
};

subtest 'from Library' => sub {
    Sub::Meta::Library->register(\&hello, Sub::Meta->new(
        sub  => \&hello,
        args => ['Int'],
    ));

    my $meta = Sub::Meta::CreatorFunction::find_submeta(\&hello);
    isa_ok $meta, 'Sub::Meta';
    is $meta->sub, \&hello;
    is $meta->args, [Sub::Meta::Param->new('Int')];
};

subtest 'finders' => sub {
    my $finders;
    $finders = Sub::Meta::CreatorFunction::finders();
    ok @$finders > 0;

    local @Sub::Meta::CreatorFunction::FINDER_CLASSES = qw(Foo MySubMeta::Finder);
    $finders = Sub::Meta::CreatorFunction::finders();
    is @$finders, 1;
    is $finders->[0], \&MySubMeta::Finder::find_materials;
};

done_testing;
