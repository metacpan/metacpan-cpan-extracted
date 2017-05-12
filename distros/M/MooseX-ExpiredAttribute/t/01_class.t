package TestObj;

use Moose;
use MooseX::ExpiredAttribute;

has 'test' => (
    traits      => [ 'Expired' ],
    is          => 'rw',
    isa         => 'Str',
    expires     => 1.5,
    lazy        => 1,
    builder     => '_build_test',
);

has 'test_2' => (
    traits      => [ 'Expired' ],
    is          => 'rw',
    isa         => 'Str',
    expires     => 1.5,
    lazy        => 1,
    builder     => '_build_test_2',
);

has 'foo' => (
    is          => 'rw',
    isa         => 'Int',
);

has 'build_times'   => ( is => 'rw', default => 0 );

has 'build_times_2' => ( is => 'rw', default => 0 );

sub _build_test {
    my $self = shift;

    $self->build_times( $self->build_times + 1 );
    'test';
}

sub _build_test_2 {
    my $self = shift;

    $self->build_times_2( $self->build_times_2 + 1 );
    'test_2';
}

package MY::testing;

use Test::More;

my $obj = TestObj->new;
my $obj2 = TestObj->new;

ok $obj->build_times == 0;
ok $obj->test eq 'test';
ok $obj->build_times == 1;
ok $obj->build_times_2 == 0;

ok $obj2->build_times == 0;

ok $obj->test eq 'test';
ok $obj->build_times == 1;

ok $obj2->test eq 'test';
ok $obj2->build_times == 1;

select( undef, undef, undef, 0.5 );     # sleep 0.5 second

ok $obj->test eq 'test';
ok $obj->build_times == 1;

select undef, undef, undef, 1.1;

ok $obj->test eq 'test';
ok $obj->build_times == 2;
ok $obj->test_2 eq 'test_2';
ok $obj->build_times_2 == 1;

ok $obj2->build_times == 1;
ok $obj2->test eq 'test';
ok $obj2->build_times == 2;

select undef, undef, undef, 0.5;        # sleep 0.5 second

ok $obj->test eq 'test';
ok $obj->build_times == 2;
ok $obj->test_2 eq 'test_2';
ok $obj->build_times_2 == 1;

select undef, undef, undef, 1.1;

$obj->test('super');
ok $obj->test eq 'super';
ok $obj->build_times == 2;

$obj->test_2('super_2');
ok $obj->test_2 eq 'super_2';
ok $obj->build_times_2 == 1;

select undef, undef, undef, 0.5;        # sleep 0.5 second

ok $obj->test eq 'super';
ok $obj->build_times == 2;

select undef, undef, undef, 1.1;

ok $obj->test eq 'test';
ok $obj->build_times == 3;

done_testing;
