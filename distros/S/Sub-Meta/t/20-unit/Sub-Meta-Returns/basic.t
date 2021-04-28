use Test2::V0;

use Sub::Meta::Returns;

sub Int() { return bless {}, 'Some::Type::Int' }
sub Str() { return bless {}, 'Some::Type::Str' }

subtest 'empty' => sub {
    my $returns = Sub::Meta::Returns->new();

    is $returns->scalar, undef;
    is $returns->list, undef;
    is $returns->void, undef;
    is $returns->coerce, undef;

    ok !$returns->has_scalar;
    ok !$returns->has_list;
    ok !$returns->has_void;
    ok !$returns->has_coerce;
};

subtest 'sinble object' => sub {
    my $returns = Sub::Meta::Returns->new( Int );

    is $returns->scalar, Int;
    is $returns->list, Int;
    is $returns->void, Int;
    is $returns->coerce, undef;

    ok $returns->has_scalar;
    ok $returns->has_list;
    ok $returns->has_void;
    ok !$returns->has_coerce;
};

subtest 'sinble string' => sub {
    my $returns = Sub::Meta::Returns->new( 'Int' );

    is $returns->scalar, 'Int';
    is $returns->list, 'Int';
    is $returns->void, 'Int';
    is $returns->coerce, undef;

    ok $returns->has_scalar;
    ok $returns->has_list;
    ok $returns->has_void;
    ok !$returns->has_coerce;
};

subtest 'arrayref' => sub {
    my $returns = Sub::Meta::Returns->new([ Int, Str ]);

    is $returns->scalar, [ Int, Str ];
    is $returns->list, [ Int, Str ];
    is $returns->void, [ Int, Str ];
    is $returns->coerce, undef;

    ok $returns->has_scalar;
    ok $returns->has_list;
    ok $returns->has_void;
    ok !$returns->has_coerce;
};

subtest 'hashref' => sub {
    subtest 'empty' => sub {
        my $returns = Sub::Meta::Returns->new({});

        is $returns->scalar, undef;
        is $returns->list, undef;
        is $returns->void, undef;
        is $returns->coerce, undef;

        ok !$returns->has_scalar;
        ok !$returns->has_list;
        ok !$returns->has_void;
        ok !$returns->has_coerce;
    };

    subtest 'specify scalar' => sub {
        my $returns = Sub::Meta::Returns->new({ scalar => Int });

        is $returns->scalar, Int;
        is $returns->list, undef;
        is $returns->void, undef;
        is $returns->coerce, undef;

        ok $returns->has_scalar;
        ok !$returns->has_list;
        ok !$returns->has_void;
        ok !$returns->has_coerce;
    };

    subtest 'specify list' => sub {
        my $returns = Sub::Meta::Returns->new({ list => Int });

        is $returns->scalar, undef;
        is $returns->list, Int;
        is $returns->void, undef;
        is $returns->coerce, undef;

        ok !$returns->has_scalar;
        ok $returns->has_list;
        ok !$returns->has_void;
        ok !$returns->has_coerce;
    };

    subtest 'specify void' => sub {
        my $returns = Sub::Meta::Returns->new({ void => Int });

        is $returns->scalar, undef;
        is $returns->list, undef;
        is $returns->void, Int;
        is $returns->coerce, undef;

        ok !$returns->has_scalar;
        ok !$returns->has_list;
        ok $returns->has_void;
        ok !$returns->has_coerce;
    };

    subtest 'specify coerce' => sub {
        my $returns = Sub::Meta::Returns->new({ coerce => !!1 });

        is $returns->scalar, undef;
        is $returns->list, undef;
        is $returns->void, undef;
        is $returns->coerce, !!1;

        ok !$returns->has_scalar;
        ok !$returns->has_list;
        ok !$returns->has_void;
        ok $returns->has_coerce;
    };

    subtest 'mixed' => sub {
        my $returns = Sub::Meta::Returns->new({ scalar => Int, list => Str, void => [Int, Str], coerce => !!1 });

        is $returns->scalar, Int;
        is $returns->list, Str;
        is $returns->void, [Int, Str];
        is $returns->coerce, !!1; 

        ok $returns->has_scalar;
        ok $returns->has_list;
        ok $returns->has_void;
        ok $returns->has_coerce;
    };
};

subtest 'list' => sub {
    subtest 'specify scalar' => sub {
        my $returns = Sub::Meta::Returns->new( scalar => Int );

        is $returns->scalar, Int;
        is $returns->list, undef;
        is $returns->void, undef;
        is $returns->coerce, undef;

        ok $returns->has_scalar;
        ok !$returns->has_list;
        ok !$returns->has_void;
        ok !$returns->has_coerce;
    };

    subtest 'specify list' => sub {
        my $returns = Sub::Meta::Returns->new( list => Int );

        is $returns->scalar, undef;
        is $returns->list, Int;
        is $returns->void, undef;
        is $returns->coerce, undef;

        ok !$returns->has_scalar;
        ok $returns->has_list;
        ok !$returns->has_void;
        ok !$returns->has_coerce;
    };

    subtest 'specify void' => sub {
        my $returns = Sub::Meta::Returns->new( void => Int );

        is $returns->scalar, undef;
        is $returns->list, undef;
        is $returns->void, Int;
        is $returns->coerce, undef;

        ok !$returns->has_scalar;
        ok !$returns->has_list;
        ok $returns->has_void;
        ok !$returns->has_coerce
    };

    subtest 'specify coerce' => sub {
        my $returns = Sub::Meta::Returns->new( coerce => !!1 );

        is $returns->scalar, undef;
        is $returns->list, undef;
        is $returns->void, undef;
        is $returns->coerce, !!1;

        ok !$returns->has_scalar;
        ok !$returns->has_list;
        ok !$returns->has_void;
        ok $returns->has_coerce
    };

    subtest 'mixed' => sub {
        my $returns = Sub::Meta::Returns->new( scalar => Int, list => Str, void => [Int, Str], coerce => !!1 );

        is $returns->scalar, Int;
        is $returns->list, Str;
        is $returns->void, [Int, Str];
        is $returns->coerce, !!1;

        ok $returns->has_scalar;
        ok $returns->has_list;
        ok $returns->has_void;
        ok $returns->has_coerce
    };
};

subtest 'setters' => sub {

    my $returns = Sub::Meta::Returns->new;

    is $returns->scalar, undef, 'scalar';
    is $returns->set_scalar('Int'), $returns, 'set_scalar';
    is $returns->scalar, 'Int', 'scalar';

    is $returns->list, undef, 'list';
    is $returns->set_list('Int'), $returns, 'set_list';
    is $returns->list, 'Int', 'list';

    is $returns->void, undef, 'void';
    is $returns->set_void('Int'), $returns, 'set_void';
    is $returns->void, 'Int', 'void';

    my $coerce = sub { };
    is $returns->coerce, undef, 'coerce';
    is $returns->set_coerce($coerce), $returns, 'set_coerce';
    is $returns->coerce, $coerce, 'coerce';
};

done_testing;
