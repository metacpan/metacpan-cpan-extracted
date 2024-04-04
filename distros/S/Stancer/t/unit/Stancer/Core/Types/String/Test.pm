package Stancer::Core::Types::String::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Core::Types::String::Stub;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub char : Tests(5) {
    ok(Stancer::Core::Types::String::Stub->new(a_char_10 => random_string(10)), '10 characters lenth');

    my $regex = qr/Must be exactly 10 characters/sm;

    my $too_short = random_string(9);
    my $too_long = random_string(11);

    throws_ok { Stancer::Core::Types::String::Stub->new(a_char_10 => $too_short) } $regex, $too_short . ' is too short';
    throws_ok { Stancer::Core::Types::String::Stub->new(a_char_10 => $too_long) } $regex, $too_long . ' is too long';

    throws_ok { Stancer::Core::Types::String::Stub->new(a_char_10 => undef) } $regex, 'undef is not valid';
    throws_ok { Stancer::Core::Types::String::Stub->new(a_char_10 => random_integer(100)) } $regex, 'Must be a string';
}

sub description : Tests(9) {
    my $message = 'Must be an string between 3 and 64 characters, tried with %s.';
    my $integer = random_integer(100);
    my $too_short = random_string(2);
    my $too_long = random_string(65);
    my $string = random_string(20);

    ok(Stancer::Core::Types::String::Stub->new(a_description => $string), $string . ' is valid');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_description => $too_short);
    } 'Stancer::Exceptions::InvalidDescription', 'Must be at least 3 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_short . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_description => $too_long);
    } 'Stancer::Exceptions::InvalidDescription', 'Must be maximum 64 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_long . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_description => $integer);
    } 'Stancer::Exceptions::InvalidDescription', 'Must be a string';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_description => undef);
    } 'Stancer::Exceptions::InvalidDescription', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub email : Tests(9) {
    my $message = 'Must be an string between 5 and 64 characters, tried with %s.';
    my $integer = random_integer(100);
    my $too_short = random_string(4);
    my $too_long = random_string(65);
    my $string = random_string(20);

    ok(Stancer::Core::Types::String::Stub->new(an_email => $string), $string . ' is valid');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_email => $too_short);
    } 'Stancer::Exceptions::InvalidEmail', 'Must be at least 5 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_short . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_email => $too_long);
    } 'Stancer::Exceptions::InvalidEmail', 'Must be maximum 64 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_long . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_email => $integer);
    } 'Stancer::Exceptions::InvalidEmail', 'Must be a string';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_email => undef);
    } 'Stancer::Exceptions::InvalidEmail', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub external_id : Tests(5) {
    my $message = 'Must be at maximum 36 characters, tried with %s.';
    my $too_long = random_string(37);
    my $string = random_string(20);

    ok(Stancer::Core::Types::String::Stub->new(an_external_id => $string), $string . ' is valid');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_external_id => $too_long);
    } 'Stancer::Exceptions::InvalidExternalId', 'Must be maximum 36 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_long . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_external_id => undef);
    } 'Stancer::Exceptions::InvalidExternalId', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub mobile : Tests(7) {
    my $message = 'Must be an string between 8 and 16 characters, tried with %s.';
    my $too_short = random_string(7);
    my $too_long = random_string(17);
    my $string = random_string(10);

    ok(Stancer::Core::Types::String::Stub->new(a_mobile => $string), $string . ' is valid');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_mobile => $too_short);
    } 'Stancer::Exceptions::InvalidMobile', 'Must be at least 8 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_short . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_mobile => $too_long);
    } 'Stancer::Exceptions::InvalidMobile', 'Must be maximum 16 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_long . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_mobile => undef);
    } 'Stancer::Exceptions::InvalidMobile', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub name : Tests(9) {
    my $message = 'Must be an string between 4 and 64 characters, tried with %s.';
    my $integer = random_integer(100);
    my $too_short = random_string(3);
    my $too_long = random_string(65);
    my $string = random_string(20);

    ok(Stancer::Core::Types::String::Stub->new(a_name => $string), $string . ' is valid');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_name => $too_short);
    } 'Stancer::Exceptions::InvalidName', 'Must be at least 4 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_short . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_name => $too_long);
    } 'Stancer::Exceptions::InvalidName', 'Must be maximum 64 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_long . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_name => $integer);
    } 'Stancer::Exceptions::InvalidName', 'Must be a string';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(a_name => undef);
    } 'Stancer::Exceptions::InvalidName', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub order_id : Tests(5) {
    my $message = 'Must be at maximum 36 characters, tried with %s.';
    my $too_long = random_string(37);
    my $string = random_string(20);

    ok(Stancer::Core::Types::String::Stub->new(an_order_id => $string), $string . ' is valid');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_order_id => $too_long);
    } 'Stancer::Exceptions::InvalidOrderId', 'Must be maximum 36 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_long . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_order_id => undef);
    } 'Stancer::Exceptions::InvalidOrderId', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub unique_id : Tests(5) {
    my $message = 'Must be at maximum 36 characters, tried with %s.';
    my $too_long = random_string(37);
    my $string = random_string(20);

    ok(Stancer::Core::Types::String::Stub->new(an_unique_id => $string), $string . ' is valid');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_unique_id => $too_long);
    } 'Stancer::Exceptions::InvalidUniqueId', 'Must be maximum 36 characters';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $too_long . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::String::Stub->new(an_unique_id => undef);
    } 'Stancer::Exceptions::InvalidUniqueId', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub varchar : Tests(17) {
    { # 6 tests
        note 'With min and max';

        ok(Stancer::Core::Types::String::Stub->new(a_varchar_5_to_10 => random_string(5)), '5 characters lenth');
        ok(Stancer::Core::Types::String::Stub->new(a_varchar_5_to_10 => random_string(7)), '5 characters lenth');
        ok(Stancer::Core::Types::String::Stub->new(a_varchar_5_to_10 => random_string(10)), '10 characters lenth');

        my $regex = qr/Must be an string between 5 and 10 characters/sm;

        my $too_short = random_string(4);
        my $too_long = random_string(11);

        throws_ok { Stancer::Core::Types::String::Stub->new(a_varchar_5_to_10 => $too_short) } $regex, $too_short . ' is too short';
        throws_ok { Stancer::Core::Types::String::Stub->new(a_varchar_5_to_10 => $too_long) } $regex, $too_long . ' is too long';

        throws_ok { Stancer::Core::Types::String::Stub->new(a_varchar_5_to_10 => undef) } $regex, 'undef is not valid';
    }

    { # 6 tests
        note 'With inversed min and max';

        ok(Stancer::Core::Types::String::Stub->new(a_varchar_10_to_5 => random_string(5)), '5 characters lenth');
        ok(Stancer::Core::Types::String::Stub->new(a_varchar_10_to_5 => random_string(7)), '5 characters lenth');
        ok(Stancer::Core::Types::String::Stub->new(a_varchar_10_to_5 => random_string(10)), '10 characters lenth');

        my $regex = qr/Must be an string between 5 and 10 characters/sm;

        my $too_short = random_string(4);
        my $too_long = random_string(11);

        throws_ok { Stancer::Core::Types::String::Stub->new(a_varchar_10_to_5 => $too_short) } $regex, $too_short . ' is too short';
        throws_ok { Stancer::Core::Types::String::Stub->new(a_varchar_10_to_5 => $too_long) } $regex, $too_long . ' is too long';

        throws_ok { Stancer::Core::Types::String::Stub->new(a_varchar_10_to_5 => undef) } $regex, 'undef is not valid';
    }

    { # 5 tests
        note 'With maximum only';

        ok(Stancer::Core::Types::String::Stub->new(a_varchar_10 => random_string(5)), '5 characters lenth');
        ok(Stancer::Core::Types::String::Stub->new(a_varchar_10 => random_string(7)), '5 characters lenth');
        ok(Stancer::Core::Types::String::Stub->new(a_varchar_10 => random_string(10)), '10 characters lenth');

        my $regex = qr/Must be at maximum 10 characters/sm;

        my $too_long = random_string(11);

        throws_ok { Stancer::Core::Types::String::Stub->new(a_varchar_10 => $too_long) } $regex, $too_long . ' is too long';

        throws_ok { Stancer::Core::Types::String::Stub->new(a_varchar_10 => undef) } $regex, 'undef is not valid';
    }
}

1;
