use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental;

sub new {
    my ($format, @orders) = @_;
    my $str = String::Incremental->new( format => $format, orders => \@orders );
    return $str;
}

{
    no strict 'refs';
    *{'String::Incremental::f'} = sub {
        return shift->_extract_incremental_chars( @_ );
    };
}

subtest 'call' => sub {
    my $str = new( 'foobar' );
    ok $str->can( '_extract_incremental_chars' );
    ok $str->can( 'f' );  # alias defined above
};

subtest 'args' => sub {
    my $str = new( 'foobar' );

    dies_ok {
        $str->f();
    } 'nothing';
};

subtest 'fixed' => sub {
    my $str = new( 'foo' );

    subtest 'live or die' => sub {
        dies_ok {
            $str->f( 'hoge' );
        };

        dies_ok {
            $str->f( 'fooo' );
        };

        lives_ok {
            $str->f( 'foo' );
        };
    };

    subtest 'return' => sub {
        my @ch = $str->f( 'foo' );
        is_deeply \@ch, [];
    };
};

subtest 'char' => sub {
    subtest 'simple' => sub {
        my $str = new( '%=', 'aux' );

        subtest 'live or die' => sub {
            lives_ok { $str->f( 'a' ) };
            lives_ok { $str->f( 'u' ) };
            lives_ok { $str->f( 'x' ) };
            dies_ok  { $str->f( 'aux' ) };
            dies_ok  { $str->f( 'au' ) };
            dies_ok  { $str->f( 'b' ) };
        };

        subtest 'return' => sub {
            my @ch;

            @ch = $str->f( 'a' );
            is_deeply \@ch, [ 'a' ];

            @ch = $str->f( 'x' );
            is_deeply \@ch, [ 'x' ];
        };
    };

    subtest 'complex' => sub {
        my $str = new( '%=-%2=-%=', 'auxz', '13579', '({#/', );

        subtest 'live or die' => sub {
            lives_ok { $str->f( 'a-11-(' ) };
            lives_ok { $str->f( 'u-37-/' ) };
            dies_ok  { $str->f( 'a-11-(-' ) };
            dies_ok  { $str->f( ' a-11-(' ) };
            dies_ok  { $str->f( 'a-11-( ' ) };
            dies_ok  { $str->f( 'a-11-' ) };
            dies_ok  { $str->f( 'b-11-(' ) };
            dies_ok  { $str->f( 'a-12-(' ) };
            dies_ok  { $str->f( 'a-11-)' ) };
        };

        subtest 'return' => sub {
            my @ch;

            @ch = $str->f( 'a-11-(' );
            is_deeply \@ch, ['a', '1', '1', '('];

            @ch = $str->f( 'u-37-/' );
            is_deeply \@ch, ['u', '3', '7', '/'];
        };
    };
};

subtest 'mixed' => sub {
    my $str = new(
        '%d-foo-%=-%06s-%2=-%2=%%-bar',
        '123',   # ::String
        'aux',   # ::Char * 1
        'hoge',  # ::String
        'abc',   # ::Char * 2
        [0..5],  # ::Char * 2
    );

    subtest 'live or die' => sub {
        lives_ok { $str->f( '123-foo-a-00hoge-aa-00%-bar' ) };
        lives_ok { $str->f( '123-foo-u-00hoge-bc-23%-bar' ) };
        lives_ok { $str->f( '123-foo-x-00hoge-cc-55%-bar' ) };
        dies_ok  { $str->f( '123-foo-a-hoge-aa-00%-bar' ) };
        dies_ok  { $str->f( '123-foo-b-00hoge-aa-00%-bar' ) };
        dies_ok  { $str->f( '123-foo-a-00hoge-ad-00%-bar' ) };
        dies_ok  { $str->f( '123-foo-a-00hoge-aa-60%-bar' ) };
    };

    subtest 'return' => sub {
        my @ch;

        @ch = $str->f( '123-foo-a-00hoge-aa-00%-bar' );
        is_deeply \@ch, [qw( a a a 0 0 )];

        @ch = $str->f( '123-foo-u-00hoge-bc-23%-bar' );
        is_deeply \@ch, [qw( u b c 2 3 )];

        @ch = $str->f( '123-foo-x-00hoge-cc-55%-bar' );
        is_deeply \@ch, [qw( x c c 5 5 )];
    };
};



done_testing;
