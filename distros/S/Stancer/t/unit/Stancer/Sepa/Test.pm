package Stancer::Sepa::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use TestCase qw(:lwp); # Must be called first to initialize logs
use Stancer::Config;
use Stancer::Sepa;
use DateTime;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars, RequireExtendedFormatting)

sub instanciate : Tests(15) {
    { # 4 tests
        my $object = Stancer::Sepa->new();

        isa_ok($object, 'Stancer::Sepa', 'Stancer::Sepa->new()');
        isa_ok($object, 'Stancer::Core::Object', 'Stancer::Sepa->new()');

        ok($object->does('Stancer::Role::Country'), 'Should use Stancer::Role::Country');
        ok($object->does('Stancer::Role::Name'), 'Should use Stancer::Role::Name');
    }

    { # 11 tests
        my $id = random_string(29);
        my $bic = bic_provider();
        my $date_birth = random_date(1950, 2000);
        my $date_mandate = random_integer(1_500_000_000, 1_600_000_000);
        my @ibans = iban_provider();
        my $mandate = random_string(34);
        my $name = random_string(64);

        my $object = Stancer::Sepa->new(
            id => $id,
            bic => $bic,
            date_birth => $date_birth,
            date_mandate => $date_mandate,
            iban => $ibans[0],
            mandate => $mandate,
            name => $name,
        );
        my $iban = uc $ibans[0];

        $iban =~ s/\s//gsm;

        isa_ok($object, 'Stancer::Sepa', 'Stancer::Sepa->new(foo => "bar")');

        is($object->id, $id, 'Should add a value for `id` property');

        is($object->bic, uc $bic, 'Should have a value for `bic` property');

        isa_ok($object->date_birth, 'DateTime', '$object->date_birth');
        is($object->date_birth->ymd, $date_birth, 'Should have expected date in it');

        isa_ok($object->date_mandate, 'DateTime', '$object->date_mandate');
        is($object->date_mandate->epoch, $date_mandate, 'Should have expected date in it');

        is($object->iban, $iban, 'Should have a value for `iban` property');
        is($object->mandate, $mandate, 'Should have a value for `mandate` property');
        is($object->name, $name, 'Should have a value for `name` property');

        my $exported = {
            bic => uc $bic,
            date_birth => $date_birth,
            date_mandate => $date_mandate,
            iban => $iban,
            mandate => $mandate,
            name => $name,
        };

        cmp_deeply_json($object, $exported, 'They should be exported');
    }
}

sub bic : Tests(19) {
    my $object = Stancer::Sepa->new();
    my @bics = bic_provider();

    is($object->bic, undef, 'Undefined by default');

    foreach my $bic (@bics) {
        $object->_reset_modified(); # Do not do this at home

        $object->bic($bic);

        is($object->bic, uc $bic, 'Should update with ' . $bic);
        cmp_deeply_json($object, { bic => uc $bic }, 'Should be exported');
    }
}

sub check : Tests(14) {
    { # 2 tests
        note 'Without ID';

        my $sepa = Stancer::Sepa->new();

        is($sepa->check, undef, 'Undefined by default');

        throws_ok { $sepa->check(random_string(29)) } qr/check is a read-only accessor/sm, 'Not writable';
    }

    { # 10 tests
        note 'With and ID already registered for verification';

        my $id = random_string(29);
        my $sepa = Stancer::Sepa->new($id);

        my $content = read_file '/t/fixtures/sepa/check/read.json';

        $mock_response->set_always(decoded_content => $content);
        $mock_ua->clear();

        isa_ok($sepa->check, 'Stancer::Sepa::Check', '$sepa->check');

        # Data are from fixtures
        is($sepa->check->id, 'sepa_fZvOCm7oDmUJhqvezEtlZwXa', 'Should have an id');
        ok($sepa->check->date_birth, 'Should have a `date_birth` value');
        is($sepa->check->response, '00', 'Should have a `response` value');
        is($sepa->check->score_name, 0.32, 'Should have a `score_name` value');
        is($sepa->check->status, Stancer::Sepa::Check::Status::CHECKED, 'Should have a `status` value');

        is($mock_ua->called_count('request'), 1, 'Should have done one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr{sepa/check}sm, 'Should use sepa check endpoint');
        like($mock_request->url, qr/$id/sm, 'Should add the SEPA id');
    }

    { # 1 test
        note 'With and ID not registered for verification';

        my $id = random_string(29);
        my $sepa = Stancer::Sepa->new($id);

        $mock_response->set_always('code', 404);
        $mock_response->set_always('decoded_content', q//);
        $mock_response->set_always('is_success', 0);
        $mock_ua->clear();

        is($sepa->check, undef, 'Should be undefined as no verification asked');

        # back to normal
        $mock_response->set_always('code', 200);
        $mock_response->set_always('is_success', 1);
    }

    { # 1 test
        note 'Exceptions are not hidden';

        my $id = random_string(29);
        my $sepa = Stancer::Sepa->new($id);

        $mock_response->set_always('code', 500);
        $mock_response->set_always('decoded_content', q//);
        $mock_response->set_always('is_success', 0);
        $mock_ua->clear();

        throws_ok { $sepa->check } 'Stancer::Exceptions::Http::InternalServerError', 'Exceptions are not hidden';

        # back to normal
        $mock_response->set_always('code', 200);
        $mock_response->set_always('is_success', 1);
    }
}

sub date_birth : Tests(17) {
    my $birth = random_date(1950, 2000);
    my ($year, $month, $day) = split qr/-/sm, $birth;
    my $dt = DateTime->new(year => $year, month => $month, day => $day);

    { # 2 tests
        note 'Default value';

        my $object = Stancer::Sepa->new();

        is($object->date_birth, undef, 'Undefined by default');
        cmp_deeply_json($object, {}, 'Should not be exported');
    }

    { # 3 tests
        note 'With a string';

        my $object = Stancer::Sepa->new();

        $object->date_birth($birth);

        isa_ok($object->date_birth, 'DateTime', '$object->date_birth');
        is($object->date_birth->ymd, $birth, 'Date is correct');
        cmp_deeply_json($object, { date_birth => $birth }, 'Should be exported');
    }

    { # 3 tests
        note 'With a DateTime object (without time)';

        my $object = Stancer::Sepa->new();

        $object->date_birth($dt);

        isa_ok($object->date_birth, 'DateTime', '$object->date_birth');
        is($object->date_birth->ymd, $birth, 'Date is correct');
        cmp_deeply_json($object, { date_birth => $birth }, 'Should be exported');
    }

    { # 4 tests
        note 'With a DateTime object (wit time)';

        my $object = Stancer::Sepa->new();
        my $hours = random_integer(0, 23);
        my $minutes = random_integer(0, 59);
        my $seconds = random_integer(0, 59);
        my $date = $dt->clone->set(hour => $hours, minute => $minutes, second => $seconds);

        $object->date_birth($date);

        isa_ok($object->date_birth, 'DateTime', '$object->date_birth');
        is($object->date_birth->ymd, $birth, 'Date is correct');
        is($object->date_birth->hms, '00:00:00', 'Should not have time');
        cmp_deeply_json($object, { date_birth => $birth }, 'Should be exported');
    }

    { # 5 tests
        note 'TimeZone have no effect (it\'s supposed to be a date)';

        my $object = Stancer::Sepa->new();

        my $config = Stancer::Config->init();
        my $delta = random_integer(1, 6);
        my $tz = DateTime::TimeZone->new(name => sprintf '+%04d', $delta * 100);

        $config->default_timezone($tz);

        $object->date_birth($dt);

        isa_ok($object->date_birth, 'DateTime', '$object->date_birth');
        is($object->date_birth->ymd, $birth, 'Date is correct');
        is($object->date_birth->hms, '00:00:00', 'Should not have time');
        isnt($object->date_birth->time_zone, $tz, 'Should not have the same timezone');
        cmp_deeply_json($object, { date_birth => $birth }, 'Should be exported');
    }
}

sub date_mandate : Tests(4) {
    my $object = Stancer::Sepa->new();
    my $date = random_integer(1_500_000_000, 1_600_000_000);

    my $config = Stancer::Config->init();
    my $delta = random_integer(1, 6);
    my $tz = DateTime::TimeZone->new(name => sprintf '+%04d', $delta * 100);

    $config->default_timezone($tz);

    is($object->date_mandate, undef, 'Undefined by default');

    $object->date_mandate($date);

    isa_ok($object->date_mandate, 'DateTime', '$object->date_mandate');
    is($object->date_mandate->epoch, $date, 'Date is correct');
    is($object->date_mandate->time_zone, $tz, 'Should have the same timezone now');
}

sub endpoint : Test {
    my $object = Stancer::Sepa->new();

    is($object->endpoint, q/sepa/);
}

sub formatted_iban : Tests(18) {
    my $object = Stancer::Sepa->new();
    my @ibans = iban_provider();

    is($object->formatted_iban, undef, 'Undefined by default');

    foreach my $iban (@ibans) {
        my $formatted = uc $iban;

        $formatted =~ s/\s//gsm;
        $formatted =~ s/(.{0,4})/$1 /gsm;
        $formatted =~ s/\s*$//sm;

        $object->iban($iban);

        is($object->formatted_iban, $formatted, 'Should return a formatted iban "' . $formatted . q/"/);
    }
}

sub iban : Tests(52) {
    my $object = Stancer::Sepa->new();
    my @ibans = iban_provider();

    is($object->iban, undef, 'Undefined by default');

    foreach my $iban (@ibans) {
        my $cleaned = uc $iban;

        $cleaned =~ s/\s//gsm;

        my $last4 = substr $cleaned, -4;

        $object->_reset_modified(); # Do not do this at home

        $object->iban($iban);

        is($object->iban, $cleaned, 'Should update with ' . $iban);
        is($object->last4, $last4, 'Should update `last4` attribute too');
        cmp_deeply_json($object, { iban => $cleaned }, 'Should be exported');
    }
}

sub mandate : Tests(3) {
    my $object = Stancer::Sepa->new();
    my $mandate = random_string(35);

    is($object->mandate, undef, 'Undefined by default');

    $object->mandate($mandate);

    is($object->mandate, $mandate, 'Should be updated');
    cmp_deeply_json($object, { mandate => $mandate }, 'Should be exported');
}

sub name : Tests(3) {
    my $object = Stancer::Sepa->new();
    my $name = random_string(64);

    is($object->name, undef, 'Undefined by default');

    $object->name($name);

    is($object->name, $name, 'Should be updated');
    cmp_deeply_json($object, { name => $name }, 'Should be exported');
}

sub populate : Tests(8) {
    my %props = (
        bic => 'TESTSEPP',
        created => 1_601_045_777,
        date_mandate => 1_601_045_728,
        last4 => '0003',
        mandate => 'mandate-identifier',
        name => 'John Doe',
    );

    my $content = read_file '/t/fixtures/sepa/read.json';

    $mock_response->set_always(decoded_content => $content);
    $mock_ua->clear();

    foreach my $key (keys %props) {
        my $object = Stancer::Sepa->new('sepa_bIvCZePYqfMlU11TANT8IqL1');

        if ($key eq 'created' || $key eq 'date_mandate') {
            isa_ok($object->$key, 'DateTime', '$object->' . $key);
            is($object->$key->epoch, $props{$key}, 'created should have right value');
        } else {
            is($object->$key, $props{$key}, $key . ' should trigger populate');
        }
    }
}

sub validate : Tests(43) {
    { # 30 tests
        note 'Ask for verification at SEPA creation';

        my $bic = bic_provider();
        my $date_birth = random_date(1950, 2000);
        my $date_mandate = random_integer(1_500_000_000, 1_600_000_000);
        my @ibans = iban_provider();
        my $mandate = random_string(34);
        my $name = random_string(10);

        my $sepa = Stancer::Sepa->new({
            bic => $bic,
            date_birth => $date_birth,
            date_mandate => $date_mandate,
            iban => $ibans[0],
            mandate => $mandate,
            name => $name,
        });

        my $check_content = read_file '/t/fixtures/sepa/check/create.json';
        my $sepa_content = read_file '/t/fixtures/sepa/read.json';
        my $new_args;

        $mock_response->set_series('decoded_content', $check_content, $sepa_content);
        $mock_ua->clear();

        $sepa->validate();

        # Only one call for now, we only have POST validation
        $new_args = $mock_request->new_args;

        is($new_args->[1], 'POST', 'Should create a new POST request');
        is($new_args->[2], Stancer::Sepa::Check->new->uri, 'Should use check location');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 6, 'Should send all setted data');

            is($data->{bic}, uc $bic, 'Should have passed "bic"');
            is($data->{date_birth}, $date_birth, 'Should have passed "date_birth"');
            is($data->{date_mandate}, $date_mandate, 'Should have passed "date_mandate"');
            is($data->{iban}, $sepa->iban, 'Should have passed "iban"');
            is($data->{mandate}, $mandate, 'Should have passed "mandate"');
            is($data->{name}, $name, 'Should have passed "name"');

            last; # We only check it once, as the "content" method should be used again in debug mode
        }

        # Data are from fixtures
        is($sepa->id, 'sepa_bIvCZePYqfMlU11TANT8IqL1', 'Sepa should have been updated');

        isa_ok($sepa->created, 'DateTime', '$sepa->created'); # First to cheat on auto-population
        is($sepa->created->epoch, 1_601_045_777, 'Should have correct creation date');

        is($sepa->bic, 'TESTSEPP', 'Sepa should have a BIC');

        isa_ok($sepa->date_birth, 'DateTime', '$sepa->date_birth');
        is($sepa->date_birth->ymd, '1977-05-25', 'Should have correct birth date');

        isa_ok($sepa->date_mandate, 'DateTime', '$sepa->date_mandate');
        is($sepa->date_mandate->epoch, 1_601_045_728, 'Should have correct mandate date');

        is($sepa->last4, '0003', 'Sepa should have last 4 digits');
        is($sepa->mandate, 'mandate-identifier', 'Sepa should have a mandate');
        is($sepa->name, 'John Doe', 'Sepa should have a name');

        isa_ok($sepa->check, 'Stancer::Sepa::Check', '$sepa->check');

        is($sepa->check->id, 'sepa_bIvCZePYqfMlU11TANT8IqL1', 'Sepa check should have been updated');

        isa_ok($sepa->check->created, 'DateTime', '$sepa->check->created');
        is($sepa->check->created->epoch, 1_612_961_992, 'Should have correct creation date');

        is($sepa->check->date_birth, undef, 'Should not have "date_birth" value');
        is($sepa->check->response, undef, 'Should not have "response" value');
        is($sepa->check->score_name, undef, 'Should not have "score_name" value');

        is($sepa->check->status, Stancer::Sepa::Check::Status::CHECK_SENT, 'Should have a status');

        # Sepa automatic call should have been triggered
        $new_args = $mock_request->new_args;

        is($new_args->[1], 'GET', 'Should create a new GET request');
        is($new_args->[2], $sepa->uri, 'Should use sepa location');
    }

    { # 13 tests
        note 'Ask for verification on already created SEPA';

        my $id = random_string(29);
        my $sepa = Stancer::Sepa->new($id);

        my $check_content = read_file '/t/fixtures/sepa/check/read.json';

        $mock_response->set_always('decoded_content', $check_content);
        $mock_ua->clear();

        $sepa->validate();

        # Only one call for now, we only have POST validation
        my $new_args = $mock_request->new_args;

        is($new_args->[1], 'POST', 'Should create a new POST request');
        is($new_args->[2], Stancer::Sepa::Check->new->uri, 'Should use check location');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 1, 'Should send all setted data');

            is($data->{id}, $id, 'Should have passed "id"');

            last; # We only check it once, as the "content" method should be used again in debug mode
        }

        # Data are from fixtures
        isa_ok($sepa->check, 'Stancer::Sepa::Check', '$sepa->check');

        is($sepa->id, 'sepa_fZvOCm7oDmUJhqvezEtlZwXa', 'Sepa ID should have been updated');
        is($sepa->check->id, 'sepa_fZvOCm7oDmUJhqvezEtlZwXa', 'Sepa check should have been updated');

        isa_ok($sepa->check->created, 'DateTime', '$sepa->check->created');
        is($sepa->check->created->epoch, 1_612_961_992, 'Should have correct creation date');

        ok($sepa->check->date_birth, 'Should not have "date_birth" value');
        is($sepa->check->response, '00', 'Should not have "response" value');
        is($sepa->check->score_name, 0.32, 'Should not have "score_name" value');

        is($sepa->check->status, Stancer::Sepa::Check::Status::CHECKED, 'Should have a status');
    }
}

1;
