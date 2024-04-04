package Stancer::Card::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Card;
use POSIX qw(floor);
use TestCase qw(:lwp);

## no critic (RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Tests(15) {
    { # 4 tests
        note 'Basic tests';

        my $object = Stancer::Card->new();

        isa_ok($object, 'Stancer::Card', 'Stancer::Card->new()');
        isa_ok($object, 'Stancer::Core::Object', 'Stancer::Card->new()');

        ok($object->does('Stancer::Role::Country'), 'Should use Stancer::Role::Country');
        ok($object->does('Stancer::Role::Name'), 'Should use Stancer::Role::Name');
    }

    { # 8 tests
        note 'Create instance with data';

        my $id = random_string(29);
        my $cvc = random_integer(100, 999);
        my $month = floor(rand(12) + 1);
        my ($sec, $min, $hour, $day, $mon, $y, $wday, $yday, $isdst) = localtime;
        my $year = floor(rand(15) + $y + 1900);
        my @cards = card_number_provider();
        my $name = random_string(64);

        my $object = Stancer::Card->new(
            id => $id,
            cvc => $cvc,
            exp_month => $month,
            exp_year => $year,
            name => $name,
            number => $cards[0],
        );

        isa_ok($object, 'Stancer::Card', 'Stancer::Card->new($data)');

        is($object->id, $id, 'Should add a value for `id` property');

        is($object->cvc, $cvc, 'Should have a value for `cvc` property');
        is($object->exp_month, $month, 'Should have a value for `exp_month` property');
        is($object->exp_year, $year, 'Should have a value for `exp_year` property');
        is($object->name, $name, 'Should have a value for `name` property');
        is($object->number, $cards[0], 'Should have a value for `number` property');

        my $exported = {
            cvc => $cvc,
            exp_month => $month,
            exp_year => $year,
            name => $name,
            number => $cards[0],
        };

        cmp_deeply_json($object, $exported, 'They should be exported');
    }

    { # 3 tests
        note 'Create instance with ID';

        my $id = random_string(29);
        my $object = Stancer::Card->new($id);

        isa_ok($object, 'Stancer::Card', 'Stancer::Card->new($id)');

        is($object->id, $id, 'Should add a value for `id` property');

        ok($object->is_not_modified, 'Modified list should be empty');
    }
}

sub brand : Tests(3) {
    my $object = Stancer::Card->new();
    my $brand = random_string(10);

    is($object->brand, undef, 'Undefined by default');

    $object->hydrate(brand => $brand);

    is($object->brand, $brand, 'Should have a value');

    throws_ok { $object->brand($brand) } qr/brand is a read-only accessor/sm, 'Not writable';
}

sub brandname : Tests(17) {
    my $object = Stancer::Card->new();
    my %names = (
        amex => 'American Express',
        dankort => 'Dankort',
        discover => 'Discover',
        jcb => 'JCB',
        maestro => 'Maestro',
        mastercard => 'MasterCard',
        visa => 'VISA',
    );

    is($object->brandname, undef, 'Undefined by default');

    for my $key (keys %names) {
        $object->hydrate(brand => $key);

        is($object->brand, $key, 'Should have "' . $key . '" as brand');
        is($object->brandname, $names{$key}, 'Should have "' . $names{$key} . '" as brand name');
    }

    my $unknown = random_string(4);

    $object->hydrate(brand => $unknown);

    is($object->brand, $unknown, 'Should have "' . $unknown . '" as brand');
    is($object->brandname, $unknown, 'Should have "' . $unknown . '" as brand name');
}

sub cvc : Tests(3) {
    my $object = Stancer::Card->new();
    my $cvc = random_integer(100, 999);

    is($object->cvc, undef, 'Undefined by default');

    $object->cvc($cvc);

    is($object->cvc, $cvc, 'Should be updated');
    cmp_deeply_json($object, { cvc => $cvc }, 'Should be exported');
}

sub endpoint : Test {
    my $object = Stancer::Card->new();

    is($object->endpoint, q/cards/);
}

sub expiration : Tests(9) {
    my $object = Stancer::Card->new();
    my $month = floor(rand(12) + 1);
    my @parts = localtime;
    my $year = floor(rand(15) + $parts[5] + 1901);

    { # 2 tests
        my $tmp = Stancer::Card->new();

        $tmp->exp_year($year);

        throws_ok {
            $tmp->expiration
        } 'Stancer::Exceptions::InvalidExpirationMonth', 'Throw exception if no month given';
        is(
            $EVAL_ERROR->message,
            'You must set an expiration month before asking for a date.',
            'Should indicate the error',
        );
    }

    { # 2 tests
        my $tmp = Stancer::Card->new();

        $tmp->exp_month($month);

        throws_ok {
            $tmp->expiration
        } 'Stancer::Exceptions::InvalidExpirationYear', 'Throw exception if no year given';
        is(
            $EVAL_ERROR->message,
            'You must set an expiration year before asking for a date.',
            'Should indicate the error',
        );
    }

    $object->exp_month($month);
    $object->exp_year($year);

    isa_ok($object->expiration, 'DateTime', '$object->expiration');

    my $date = $object->expiration;
    my $ref = DateTime->last_day_of_month(year => $year, month => $month);

    is($date->year, $year, 'Should have `exp_year` as year');
    is($date->month, $month, 'Should have `exp_month` as month');
    is($date->day, $ref->day, 'Should have the last day of indicate month');

    is($date->hms, '00:00:00', 'Should not have time');
}

sub exp_month : Tests(3) {
    my $object = Stancer::Card->new();
    my $month = floor(rand(12) + 1);

    is($object->exp_month, undef, 'Undefined by default');

    $object->exp_month($month);

    is($object->exp_month, $month, 'Should be updated');
    cmp_deeply_json($object, { exp_month => $month }, 'Should be exported');
}

sub exp_year : Tests(3) {
    my $object = Stancer::Card->new();

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
    my $value = floor(rand(15) + $year + 1900);

    is($object->exp_year, undef, 'Undefined by default');

    $object->exp_year($value);

    is($object->exp_year, $value, 'Should be updated');
    cmp_deeply_json($object, { exp_year => $value }, 'Should be exported');
}

sub funding : Tests(3) {
    my $object = Stancer::Card->new();
    my $funding = random_string(10);

    is($object->funding, undef, 'Undefined by default');

    $object->hydrate(funding => $funding);

    is($object->funding, $funding, 'Should have a value');

    throws_ok { $object->funding($funding) } qr/funding is a read-only accessor/sm, 'Not writable';
}

sub name : Tests(3) {
    my $object = Stancer::Card->new();
    my $name = random_string(64);

    is($object->name, undef, 'Undefined by default');

    $object->name($name);

    is($object->name, $name, 'Should be updated');
    cmp_deeply_json($object, { name => $name }, 'Should be exported');
}

sub nature : Tests(3) {
    my $object = Stancer::Card->new();
    my $nature = random_string(10);

    is($object->nature, undef, 'Undefined by default');

    $object->hydrate(nature => $nature);

    is($object->nature, $nature, 'Should have a value');

    throws_ok { $object->nature($nature) } qr/nature is a read-only accessor/sm, 'Not writable';
}

sub network : Tests(3) {
    my $object = Stancer::Card->new();
    my $network = random_string(10);

    is($object->network, undef, 'Undefined by default');

    $object->hydrate(network => $network);

    is($object->network, $network, 'Should have a value');

    throws_ok { $object->network($network) } qr/network is a read-only accessor/sm, 'Not writable';
}

sub number : Tests(109) {
    my $object = Stancer::Card->new();
    my @cards = card_number_provider();

    is($object->number, undef, 'Undefined by default');

    my $number_message = 'Should be updated with' . q/ / x 6;
    my $number_length = length $number_message;
    my $last4_message = 'Last4 should be present too';
    my $last4_length = length $last4_message;

    foreach my $number (@cards) {
        my $last4 = substr $number, -4;
        my $number_total = $number_length + length $number;
        my $last4_pad = $number_total - 4 - $last4_length;

        $object->number($number);

        is($object->number, $number, $number_message . $number);
        is($object->last4, $last4, $last4_message . (q/ / x $last4_pad) . $last4);
        cmp_deeply_json($object, { number => $number }, 'Should be exported');
    }
}

sub populate : Tests(11) {
    my %props = (
        brand => 'mastercard',
        country => 'US',
        created => 1_579_010_740,
        exp_month => 2,
        exp_year => 2020,
        funding => 'credit',
        last4 => '4444',
        name => 'John Doe',
        nature => 'personnal',
        network => 'mastercard',
    );

    my $content = read_file '/t/fixtures/card/read.json';

    $mock_response->set_always(decoded_content => $content);

    foreach my $key (keys %props) {
        my $object = Stancer::Card->new('card_ub99idEIFcbK517ZrKBIrt4y');

        if ($key eq 'created') {
            isa_ok($object->created, 'DateTime', '$card->created');
            is($object->created->epoch, $props{$key}, 'created should have right value');
        } else {
            is($object->$key, $props{$key}, $key . ' should trigger populate');
        }
    }
}

## no critic (Capitalization)
sub toJSON : Tests(3) {
    my $object = Stancer::Card->new();
    my $id = random_string(29);

    my ($sec, $min, $hour, $mday, $mon, $y, $wday, $yday, $isdst) = localtime;
    my $year = random_integer(15) + $y + 1900;
    my $month = random_integer(1, 12);

    my $brand = random_string(10);
    my $country = random_string(2);
    my $name = random_string(10);
    my $number = card_number_provider();
    my $cvc = random_integer(100, 999);

    $object->hydrate({
        brand => $brand,
        country => $country,
        name => $name,
        number => $number,
        exp_year => $year,
        exp_month => $month,
        cvc => $cvc,
    });

    my $expected = to_json {
        name => $name,
        number => $number,
        exp_year => $year,
        exp_month => $month,
        cvc => $cvc,
    }, {canonical => 1}; # mandatory for testing otherwise key order can vary

    eq_or_diff($object->toJSON(), $expected, 'Should return everything except created');

    $object->hydrate({
        id => $id,
    });

    $object->_reset_modified(); # Do not do this at home

    eq_or_diff($object->toJSON(), q/"/ . $id . q/"/, 'If an ID is present, everything else is skipped');

    $object->name($name);
    $object->number($number);

    my $modified = to_json {
        name => $name,
        number => $number,
    }, {canonical => 1}; # mandatory for testing otherwise key order can vary

    eq_or_diff($object->toJSON(), $modified, 'Should return modified values');
}

sub tokenize : Tests(5) {
    my $object = Stancer::Card->new();

    is($object->tokenize, undef, 'Undefined by default');

    $object->tokenize(1);

    is($object->tokenize, 1, 'Should be true');
    cmp_deeply_json($object, decode_json encode_json { tokenize => \1 }, 'Should be exported');

    $object->tokenize(0);

    is($object->tokenize, 0, 'Should be false');
    cmp_deeply_json($object, decode_json encode_json { tokenize => \0 }, 'Should be exported too');
}

1;
