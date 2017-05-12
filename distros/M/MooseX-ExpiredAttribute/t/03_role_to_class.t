package TestObjRole;

use Moose::Role;
use MooseX::ExpiredAttribute;

has 'test' => (
    traits      => [ 'Expired' ],
    is          => 'rw',
    isa         => 'Str',
    expires     => 1.5,
    lazy        => 1,
    builder     => '_build_test',
);

has 'build_times' => ( is => 'rw', default => 0 );

sub _build_test {
    my $self = shift;

    $self->build_times( $self->build_times + 1 );
    'test';
}

package TestObj;

use Moose;

with 'TestObjRole';

__PACKAGE__->meta->make_immutable;

package MY::testing;

use Test::More;

my $obj = TestObj->new;
my $obj2 = TestObj->new;

ok $obj->build_times == 0;
ok $obj->test eq 'test';
ok $obj->build_times == 1;

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

ok $obj2->build_times == 1;
ok $obj2->test eq 'test';
cmp_ok $obj2->build_times, '==', 2;

select undef, undef, undef, 0.5;        # sleep 0.5 second

ok $obj->test eq 'test';
ok $obj->build_times == 2;

select undef, undef, undef, 1.1;

$obj->test('super');
ok $obj->test eq 'super';
ok $obj->build_times == 2;

select undef, undef, undef, 0.5;        # sleep 0.5 second

ok $obj->test eq 'super';
ok $obj->build_times == 2;

select undef, undef, undef, 1.1;

ok $obj->test eq 'test';
ok $obj->build_times == 3;

done_testing;
