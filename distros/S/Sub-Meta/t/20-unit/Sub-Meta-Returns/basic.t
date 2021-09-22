use Test2::V0;

use Sub::Meta::Returns;
use Sub::Meta::Test qw(sub_meta_returns);

sub Int() { return bless {}, 'Some::Type::Int' }
sub Str() { return bless {}, 'Some::Type::Str' }

subtest 'empty' => sub {
    my $returns = Sub::Meta::Returns->new();

    is $returns, sub_meta_returns({
        scalar => undef,
        list   => undef,
        void   => undef,
        coerce => undef,
    });
};

subtest 'single object' => sub {
    my $returns = Sub::Meta::Returns->new( Int );

    is $returns, sub_meta_returns({
        scalar => Int,
        list   => Int,
        void   => Int,
        coerce => undef,
    });
};

subtest 'single string' => sub {
    my $returns = Sub::Meta::Returns->new( 'Int' );

    is $returns, sub_meta_returns({
        scalar => 'Int',
        list   => 'Int',
        void   => 'Int',
        coerce => undef,
    });
};

subtest 'arrayref' => sub {
    my $returns = Sub::Meta::Returns->new([ Int, Str ]);

    is $returns, sub_meta_returns({
        scalar => [Int,Str],
        list   => [Int,Str],
        void   => [Int,Str],
        coerce => undef,
    });
};

subtest 'hashref' => sub {
    subtest 'empty' => sub {
        my $returns = Sub::Meta::Returns->new({});

        is $returns, sub_meta_returns({
            scalar => undef,
            list   => undef,
            void   => undef,
            coerce => undef,
        });
    };

    subtest 'specify scalar' => sub {
        my $returns = Sub::Meta::Returns->new({ scalar => Int });

        is $returns, sub_meta_returns({
            scalar => Int,
            list   => undef,
            void   => undef,
            coerce => undef,
        });
    };

    subtest 'specify list' => sub {
        my $returns = Sub::Meta::Returns->new({ list => Int });

        is $returns, sub_meta_returns({
            scalar => undef,
            list   => Int,
            void   => undef,
            coerce => undef,
        });
    };

    subtest 'specify void' => sub {
        my $returns = Sub::Meta::Returns->new({ void => Int });

        is $returns, sub_meta_returns({
            scalar => undef,
            list   => undef,
            void   => Int,
            coerce => undef,
        });
    };

    subtest 'specify coerce' => sub {
        my $returns = Sub::Meta::Returns->new({ coerce => !!1 });

        is $returns, sub_meta_returns({
            scalar => undef,
            list   => undef,
            void   => undef,
            coerce => !!1,
        });
    };

    subtest 'mixed' => sub {
        my $returns = Sub::Meta::Returns->new({ scalar => Int, list => Str, void => [Int, Str], coerce => !!1 });

        is $returns, sub_meta_returns({
            scalar => Int,
            list   => Str,
            void   => [Int,Str],
            coerce => !!1,
        });
    };
};

subtest 'list' => sub {
    subtest 'specify scalar' => sub {
        my $returns = Sub::Meta::Returns->new( scalar => Int );

        is $returns, sub_meta_returns({
            scalar => Int,
            list   => undef,
            void   => undef,
            coerce => undef,
        });
    };

    subtest 'specify list' => sub {
        my $returns = Sub::Meta::Returns->new( list => Int );

        is $returns, sub_meta_returns({
            scalar => undef,
            list   => Int,
            void   => undef,
            coerce => undef,
        });
    };

    subtest 'specify void' => sub {
        my $returns = Sub::Meta::Returns->new( void => Int );

        is $returns, sub_meta_returns({
            scalar => undef,
            list   => undef,
            void   => Int,
            coerce => undef,
        });
    };

    subtest 'specify coerce' => sub {
        my $returns = Sub::Meta::Returns->new( coerce => !!1 );

        is $returns, sub_meta_returns({
            scalar => undef,
            list   => undef,
            void   => undef,
            coerce => !!1,
        });
    };

    subtest 'mixed' => sub {
        my $returns = Sub::Meta::Returns->new( scalar => Int, list => Str, void => [Int, Str], coerce => !!1 );

        is $returns, sub_meta_returns({
            scalar => Int,
            list   => Str,
            void   => [Int, Str],
            coerce => !!1,
        });
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
