use Test2::V0;

use Sub::Meta;
use Sub::Meta::TypeSub;
use Sub::Meta::Type;

subtest 'exceptions' => sub {
    like dies { Sub::Meta::TypeSub->new() },   qr/^Need to supply submeta_type/;
    like dies { Sub::Meta::TypeSub->new({}) }, qr/^Need to supply submeta_type/;
};

subtest 'attributes' => sub {
    my $submeta = Sub::Meta->new(
        args    => ['Int'],
        returns => 'Int',
    );
    my $find_submeta = sub { };

    my $SubMeta = Sub::Meta::Type->new(
        submeta              => $submeta,
        submeta_strict_check => 0,
        find_submeta         => $find_submeta,
    );

    my $Sub = Sub::Meta::TypeSub->new(
        submeta_type => $SubMeta,
    );

    is $Sub->submeta_type, $SubMeta;

    subtest 'customize name' => sub {
        my $type = Sub::Meta::TypeSub->new(
            submeta_type => $SubMeta,
            name         => 'MySub',
        );

        is $type->name, 'MySub';
    };
};

done_testing;
