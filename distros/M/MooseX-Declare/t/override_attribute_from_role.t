use Test::More tests => 1;
use Test::Fatal;

use MooseX::Declare;

role ProvidesFooAttribute {
    has foo => ( is => 'ro' );
}

is( exception {
    class Consumer {
        with 'ProvidesFooAttribute';
        has '+foo' => ( isa => 'Int' );
    }
}, undef, 'Delayed role application does not play nice with has +foo');
