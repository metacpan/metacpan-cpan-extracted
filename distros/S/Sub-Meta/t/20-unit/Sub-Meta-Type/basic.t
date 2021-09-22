use Test2::V0;

use Sub::Meta;
use Sub::Meta::Type;
use Types::Standard -types;

subtest 'exceptions' => sub {
    like dies { Sub::Meta::Type->new() },                                         qr/^Need to supply submeta/;
    like dies { Sub::Meta::Type->new({}) },                                       qr/^Need to supply submeta/;
    like dies { Sub::Meta::Type->new(submeta => '') },                            qr/^Need to supply submeta_strict_check/;
    like dies { Sub::Meta::Type->new(submeta => '', submeta_strict_check => 1) }, qr/^Need to supply find_submeta/;
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

    is $SubMeta->submeta, $submeta;
    is $SubMeta->submeta_strict_check, 0;
    is $SubMeta->find_submeta, $find_submeta;
};

subtest 'customize name' => sub {
    my $SubMeta = Sub::Meta::Type->new(
        submeta              => Sub::Meta->new,
        submeta_strict_check => 0,
        find_submeta         => sub {},
        name                 => 'MySubMeta',
    );

    is $SubMeta->name, 'MySubMeta';
};

done_testing;
