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

subtest 'args' => sub {
    my $str = new(
        '%d-foo-%2=-%04s-%%-bar',
        '123',
        'abc',
        'hoge',
    );

    dies_ok {
        $str->char();
    } 'nothing';

    dies_ok {
        $str->char( 'foo' );
    } 'invalid: not is-a Int';

    dies_ok {
        $str->char( 2 );
    } 'out of index';

    lives_ok {
        $str->char( 0 );
    };
};

subtest 'return' => sub {
    my $str = new(
        '%d-foo-%2=-%04s-%%-bar',
        '123',
        'abc',
        'hoge',
    );
    is "$str", '123-foo-aa-hoge-%-bar';

    my $ch;

    $ch = $str->char( 0 );
    isa_ok $ch, 'String::Incremental::Char';
    is "$ch", 'a';

    $ch = $str->char( 1 );
    isa_ok $ch, 'String::Incremental::Char';
    is "$ch", 'a';

    subtest 'fetch "Char" and increment' => sub {
        my ($ch0, $ch1) = ( $str->char( 0 ), $str->char( 1 ) );

        $ch0++;
        is "$str", '123-foo-ba-hoge-%-bar';

        $ch1++;
        $ch1++;
        is "$str", '123-foo-bc-hoge-%-bar';

        $ch1++;
        is "$str", '123-foo-ca-hoge-%-bar';
    };
};

done_testing;
