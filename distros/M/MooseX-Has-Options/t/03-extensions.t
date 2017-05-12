use strict;
use warnings;

use Test::Most;

do {
    package TestOptions;

    use Moose;
    use MooseX::Has::Options qw(NativeTypes NoInit);
    use namespace::autoclean;

    has 'no_init_attribute' => qw(:ro :lazy_build :no_init :string);

    has 'arrayref_attribute' =>
        qw(:ro :required :array),
        handles => {
            add_to_arrayref   => 'push',
            arrayref_elements => 'elements',
        };

    has 'hashref_attribute' =>
        qw(:ro :hash),
        isa     => 'HashRef[Int]',
        default => sub { { foo => 1, bar => 2 } },
        handles => { hash_value => 'get' };


    sub _build_no_init_attribute { 'foo' }
};

my $test_obj;

lives_ok {
    $test_obj = TestOptions->new(
        arrayref_attribute => ['crash'],
        no_init_attribute  => 'bar',
    );
} "create object";

is($test_obj->no_init_attribute, 'foo', ":no_init honored");

$test_obj->add_to_arrayref('boom', 'bang');

is_deeply([$test_obj->arrayref_elements], [qw(crash boom bang)], 'array delegation');

is($test_obj->hash_value('foo'), 1, 'hash delegation');


done_testing();
