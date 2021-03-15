use Test2::V0;
use Test2::Require::Module 'Sub::WrapInType', '0.04';
use Test2::Require::Module 'Types::Standard';

use Sub::WrapInType;
use Types::Standard -types;

use Sub::Meta::Creator;
use Sub::Meta::Finder::SubWrapInType;

subtest 'create' => sub {
    my $creator = Sub::Meta::Creator->new(
        finders => [ \&Sub::Meta::Finder::SubWrapInType::find_materials ],
    );

    subtest 'not_sub_wrap_in_type' => sub {
        is $creator->create(sub { }), undef, 'not_sub_wrap_in_type';
        is $creator->create(bless sub {}, 'Some'), undef, 'not_sub_wrap_in_type';
    };

    subtest 'case_positional' => sub {
        my $sub = wrap_sub [Str] => Str, sub {};

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!0, 'is_method';
        is scalar @{$meta->args}, 1;

        note 'args';
        ok $meta->args->[0]->type == Str;
        ok $meta->args->[0]->positional;
        ok $meta->args->[0]->required;

        note 'returns';
        ok $meta->returns->list == Str;
        ok $meta->returns->scalar == Str;

        is $meta->nshift, 0, 'nshift';
        ok !$meta->invocant, 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_named' => sub {
        my $sub = wrap_sub { a => Str } => Str, sub {};

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!0, 'is_method';

        note 'args'; 
        is scalar @{$meta->args}, 1;
        ok $meta->args->[0]->type == Str;
        ok $meta->args->[0]->named;
        ok $meta->args->[0]->required;
        is $meta->args->[0]->name, 'a';

        note 'returns'; 
        ok $meta->returns->list == Str;
        ok $meta->returns->scalar == Str;

        is $meta->nshift, 0, 'nshift';
        ok !$meta->invocant, 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_method_positional' => sub {
        my $sub = wrap_method [Str] => Str, sub {};

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!1, 'is_method';

        note 'args';
        is scalar @{$meta->args}, 1;
        ok $meta->args->[0]->type == Str;
        ok $meta->args->[0]->positional;
        ok $meta->args->[0]->required;

        note 'returns';
        ok $meta->returns->list == Str;
        ok $meta->returns->scalar == Str;

        is $meta->nshift, 1, 'nshift';
        isa_ok $meta->invocant, 'Sub::Meta::Param';
        ok $meta->invocant->invocant;
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_method_named' => sub {
        my $sub = wrap_method { a => Str } => Str, sub {};
    
        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!1, 'is_method';

        note 'args';
        is scalar @{$meta->args}, 1;
        ok $meta->args->[0]->type == Str;
        ok $meta->args->[0]->named;
        ok $meta->args->[0]->required;
        is $meta->args->[0]->name, 'a';

        note 'returns';
        ok $meta->returns->list == Str;
        ok $meta->returns->scalar == Str;

        is $meta->nshift, 1, 'nshift';
        isa_ok $meta->invocant, 'Sub::Meta::Param';
        ok $meta->invocant->invocant;
        ok !$meta->slurpy, 'slurpy';
    };
};

done_testing;
