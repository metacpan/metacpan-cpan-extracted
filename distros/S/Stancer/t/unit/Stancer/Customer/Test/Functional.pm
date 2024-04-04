package Stancer::Customer::Test::Functional;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Customer;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars, RequireExtendedFormatting)

sub get_data : Tests(11) {
    # 404
    throws_ok(
        sub { Stancer::Customer->new('cust_' . random_string(24))->populate() },
        'Stancer::Exceptions::Http::NotFound',
        'Should throw a NotFound (404) error',
    );

    my $object;

    # Complete customer
    $object = Stancer::Customer->new('cust_PpdYwq0ZPdoags46d5cB9HpQ')->populate();

    isa_ok($object, 'Stancer::Customer', 'Stancer::Customer->new($id)');

    is($object->name, 'John Doe', 'Should have a name (complete)');
    is($object->email, 'john.doe@example.com', 'Should have a email (complete)');
    is($object->mobile, '+33666172730', 'Should have a mobile (complete)'); # Random generated number
    is($object->external_id, '6d378a8b-0849-4ab6-96a7-c107bd613852', 'Should have an external id (complete)');

    # Partial customer (no mobile)
    $object = Stancer::Customer->new('cust_sNYCnYGw12Cj606FnM8a3gbu')->populate();

    isa_ok($object, 'Stancer::Customer', 'Stancer::Customer->new($id)');

    is($object->name, 'John Doe', 'Should have a name (partial)');
    is($object->email, 'john.doe@example.com', 'Should have a email (partial)');
    is($object->mobile, undef, 'Should not have a mobile (partial)');
    is($object->external_id, undef, 'Should not have an external id (partial)');
}

sub del : Tests {
    my $object = Stancer::Customer->new;
    my $tag = random_string(5);

    $object->name('John Doe (' . $tag . q/)/);
    $object->email('john.doe+' . $tag . '@example.com');
    $object->send();

    my $id = $object->id;

    like($id, qr/^cust_\w{24}/sm, 'Should have an ID');

    is($object->del(), $object, 'Should return itself');
    is($object->id, undef, 'Deletion removes ID');

    throws_ok(
        sub { Stancer::Customer->new($id)->populate() },
        'Stancer::Exceptions::Http::NotFound',
        'Should throw a NotFound (404) error',
    );
}

sub send_global : Tests(16) {
    { # 4 tests
        note 'Partial data';

        my $tag = random_string(5);
        my $attrs = {
            email => 'john.doe+' . $tag . '@example.com',
            mobile => random_phone(),
        };

        foreach my $attr (keys %{$attrs}) {
            my $object = Stancer::Customer->new;

            $object->name('John Doe (' . $tag . q/)/);
            $object->$attr($attrs->{$attr});

            isa_ok($object->send(), 'Stancer::Customer', '$object->send() (with only "' . $attr . q/")/);

            ok(defined $object->id, 'Should have an id');
        }
    }

    my $tag = random_string(5);
    my $phone = random_phone();
    my $external_id = random_string(36);
    my $id;

    { # 2 tests
        note 'All data (almost)';

        my $object = Stancer::Customer->new(
            name => 'John Doe (' . $tag . q/)/,
            email => 'john.doe+' . $tag . '@example.com',
            mobile => $phone,
        );

        isa_ok($object->send(), 'Stancer::Customer', '$object->send()');
        like($object->id, qr/^cust_\w{24}/sm, 'Should have an ID');

        $id = $object->id;
    }

    { # 3 tests
        note 'No duplicate';

        my $object = Stancer::Customer->new(
            name => 'John Doe (' . $tag . q/)/,
            email => 'john.doe+' . $tag . '@example.com',
            mobile => $phone,
        );
        my $message = 'Customer already exists, you may want to update it instead creating a new one';

        throws_ok { $object->send() } 'Stancer::Exceptions::Http::Conflict', 'Customer already exists';
        like($EVAL_ERROR->message, qr/^$message [(]cust_\w{24}[)]$/sm, 'Should indicate the error');
        like($EVAL_ERROR->message, qr/$id/sm, 'Should indicate the id');
    }

    { # 7 tests
        note 'External_id may allow duplicates';

        my $object1 = Stancer::Customer->new(
            name => 'John Doe (' . $tag . q/)/,
            email => 'john.doe+' . $tag . '@example.com',
            mobile => $phone,
            external_id => $external_id,
        );

        isa_ok($object1->send(), 'Stancer::Customer', '$object->send()');
        like($object1->id, qr/^cust_\w{24}/sm, 'Should have an ID');
        ok($object1->id ne $id, 'But not the same');

        my $object2 = Stancer::Customer->new(
            name => 'John Doe (' . $tag . q/)/,
            email => 'john.doe+' . $tag . '@example.com',
            mobile => $phone,
            external_id => random_string(36),
        );

        isa_ok($object2->send(), 'Stancer::Customer', '$object->send()');
        like($object2->id, qr/^cust_\w{24}/sm, 'Should have an ID');
        ok($object2->id ne $id, 'But not the same as initial payment');
        ok($object2->id ne $object1->id, 'But not the same as the previous');
    }

    { # 2 tests
        note 'External id can have duplicates too';

        my $object = Stancer::Customer->new(
            name => 'John Doe (' . $tag . q/)/,
            email => 'john.doe+' . $tag . '@example.com',
            mobile => $phone,
            external_id => $external_id,
        );
        my $message = 'Customer already exists, you may want to update it instead creating a new one';

        throws_ok { $object->send() } 'Stancer::Exceptions::Http::Conflict', 'Customer already exists';
        like($EVAL_ERROR->message, qr/^$message [(]cust_\w{24}[)]$/sm, 'Should indicate the error');
    }
}

sub update : Tests(12) {
    my $tag = random_string(5);
    my $attrs = {
        name => 'John Doe (' . $tag . q/)/,
        email => 'john.doe+' . $tag . '@example.com',
        mobile => random_phone(),
        external_id => random_string(36),
    };

    my $object = Stancer::Customer->new;

    $object->mobile(random_phone());
    $object->send();

    my $id = $object->id;

    foreach my $attr (keys %{$attrs}) {
        $object->$attr($attrs->{$attr});

        isa_ok($object->send(), 'Stancer::Customer', 'Should do an update for "' . $attr . q/"/);

        is($object->id, $id, 'Should not change the id');

        my $obj = Stancer::Customer->new($id)->populate();

        is($obj->$attr, $attrs->{$attr}, q/"/ . $attr . '" should have been modified');
    }
}

1;
