package Stancer::Auth::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Auth;
use Stancer::Auth::Status;
use TestCase;

## no critic (ProhibitPunctuationVars, RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Tests(9) {
    { # 3 tests
        note 'Empty new instance';

        my $object = Stancer::Auth->new();

        isa_ok($object, 'Stancer::Auth', 'Stancer::Auth->new()');
        isa_ok($object, 'Stancer::Core::Object', 'Stancer::Auth->new()');

        my $data = $object->TO_JSON();

        is($data->{status}, Stancer::Auth::Status::REQUEST, 'Should have a default status');
    }

    { # 6 tests
        note 'Instance completed at creation';

        my $redirect_url = 'https://' . random_string(50);
        my $return_url = 'https://' . random_string(50);
        my $status = random_string(10);
        my $data = {
            redirect_url => $redirect_url,
            return_url => $return_url,
            status => $status,
        };
        my $object = Stancer::Auth->new($data);

        isa_ok($object, 'Stancer::Auth', 'Stancer::Auth->new($data)');
        isa_ok($object, 'Stancer::Core::Object', 'Stancer::Auth->new($data)');

        is($object->redirect_url, $redirect_url, 'Should add a value for `redirect_url` property');
        is($object->return_url, $return_url, 'Should add a value for `return_url` property');
        is($object->status, $status, 'Should add a value for `status` property');

        cmp_deeply($object->TO_JSON, $data, 'They should be exported');
    }
}

sub redirect_url : Tests(3) {
    my $object = Stancer::Auth->new();
    my $redirect_url = 'https://' . random_string(50);

    is($object->redirect_url, undef, 'Undefined by default');

    $object->hydrate(redirect_url => $redirect_url);

    is($object->redirect_url, $redirect_url, 'Should have a value');

    dies_ok { $object->redirect_url($redirect_url) } 'Not writable';
}

sub return_url : Tests(3) {
    my $object = Stancer::Auth->new();
    my $return_url = 'https://' . random_string(50);
    my $exported = {
        return_url => $return_url,
        status => Stancer::Auth::Status::REQUEST,
    };

    is($object->return_url, undef, 'Undefined by default');

    $object->return_url($return_url);

    is($object->return_url, $return_url, 'Should be updated');
    cmp_deeply($object->TO_JSON, $exported, 'Should export it');
}

sub status : Tests(3) {
    my $object = Stancer::Auth->new();
    my $status = random_string(10);

    is($object->status, Stancer::Auth::Status::REQUEST, '"Stancer::Auth::Status::REQUEST" by default');

    $object->hydrate(status => $status);

    is($object->status, $status, 'Should have a value');

    dies_ok { $object->status($status) } 'Not writable';
}

1;
