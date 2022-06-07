#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests;
use Scalar::Util 'refaddr';
use DateTime;

#$MooseX::Extended::Debug = 1;

my $clone_end_date_called = 0;

package My::Class {
    use MooseX::Extended types => [qw(NonEmptyStr HashRef InstanceOf ArrayRef Int)];

    param name => ( isa => NonEmptyStr );

    # payload uses dclone, read-write, but using set_payload for the writer
    param payload => (
        isa    => HashRef,
        clone  => 1,
        writer => 1,
    );

    # start_date uses cloning sub, read only
    param start_date => (
        isa   => InstanceOf ['DateTime'],
        clone => sub ( $self, $name, $value ) {
            $clone_end_date_called = 0,
              return $value->clone;
        },
    );

    # end_date using clone builder, read only
    param end_date => (
        isa   => InstanceOf ['DateTime'],
        clone => '_clone_end_date',
    );

    sub _clone_end_date ( $self, $name, $value ) {
        $clone_end_date_called = 1;
        return $value->clone;
    }

    # clone, read-write, but with rw_aref being overloaded
    field rw_aref => ( is => 'rw', isa => ArrayRef [Int], clone => 1, default => sub { [ 1, 2, 3 ] } );

    sub BUILD ( $self, @ ) {
        if ( $self->end_date < $self->start_date ) {
            croak("End date must not be before start date");
        }
    }
}

my $payload = {
    this => [ 1, 2, 4 ],
    that => {
        is      => 'going',
        'to be' => 'cloned',
    },
};

my $start_date = DateTime->new(
    day   => 2,
    month => 3,
    year  => 1987,
);

my $end_date = DateTime->new(
    day   => 22,
    month => 7,
    year  => 1987,
);

my $object = My::Class->new(
    name       => 'Ovid',
    payload    => $payload,
    start_date => $start_date,
    end_date   => $end_date,
);

is $object->name, 'Ovid', 'Our name should be correct';
ok my $recovered = $object->payload, 'We should be able to fetch our object payload';
eq_or_diff $recovered, $payload, '... and it should have the correct data';
cmp_ok refaddr($recovered), '!=', refaddr($payload), '... but it should not be an alias to the original data structure';
$payload->{that}{foo} = 42;
ok !exists $object->payload->{that}{foo}, '... and mutating the state of the original data structure should not change our data structure';

my $recovered2 = $object->payload;
cmp_ok refaddr($recovered2), '!=', refaddr($payload),   '... but it should not be an alias to the original data structure';
cmp_ok refaddr($recovered2), '!=', refaddr($recovered), '... but it should not be an alias to the original data structure';

my $new_payload = {};
$object->set_payload($new_payload);
eq_or_diff $object->payload, {}, 'We should be able to set our new value';
$new_payload->{foo} = 1;
eq_or_diff $object->payload, {}, '... but changing the original data structure does not change our attribute value';

my $cloned_start_date = $object->start_date;
ok !$clone_end_date_called, 'We should be able to fetch our start date';
cmp_ok refaddr($cloned_start_date), '!=', refaddr($start_date), '... but it should not be an alias to the original data start date';

my $cloned_end_date = $object->end_date;
ok $clone_end_date_called, 'We should be able to fetch our end date';
cmp_ok refaddr($cloned_end_date), '!=', refaddr($end_date), '... but it should not be an alias to the original data end date';

$clone_end_date_called = 0;
my $cloned_end_date2 = $object->end_date;
ok $clone_end_date_called, 'We should be able to fetch our end date';
cmp_ok refaddr($cloned_end_date2), '!=', refaddr($cloned_end_date), '... and it should again be a clone';

eq_or_diff my $rw_aref = $object->rw_aref, [ 1, 2, 3 ], 'We should be able to read cloned fields';
cmp_ok refaddr($rw_aref), '!=', refaddr( $object->rw_aref ), '... just like we do with params';
my $new_val = [ 4, 3, 2 ];
ok $object->rw_aref($new_val), '... and set them if they are read-write';
cmp_ok refaddr( $object->rw_aref ), '!=', refaddr($new_val), '... and yup, still cloned';
eq_or_diff $object->rw_aref, [ 4, 3, 2 ], '... with the correct data';

throws_ok { $object->rw_aref( 1, 2 ) }
qr/Too many arguments/,
  "Perl's signatures allow us to feel confident we cannot pass too many arguments";

throws_ok {
    My::Class->new(
        name       => 'Ovid',
        payload    => $payload,
        start_date => $end_date,
        end_date   => $start_date,
    );
}
qr/End date must not be before start date/,
  'Our BUILD methods should be called as expected';

done_testing;
