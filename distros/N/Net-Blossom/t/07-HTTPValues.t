use strictures 2;

use Test::More;

use Net::Blossom::Error;
use Net::Blossom::PaymentRequired;
use Net::Blossom::Response;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

sub valid_response_args {
    return (
        method  => 'GET',
        url     => 'https://cdn.example.com/blob',
        status  => 200,
        reason  => 'OK',
        headers => { 'content-type' => 'application/octet-stream' },
        content => 'blob',
    );
}

sub valid_error_args {
    return (
        method   => 'GET',
        url      => 'https://cdn.example.com/blob',
        status   => 404,
        reason   => 'Not Found',
        x_reason => 'missing',
        headers  => { 'x-reason' => 'missing' },
        body     => '',
    );
}

subtest 'Response validates required HTTP fields' => sub {
    my $response = Net::Blossom::Response->new(valid_response_args());
    is($response->status, 200, 'valid response constructed');

    for my $field (qw(method url status reason)) {
        my %args = valid_response_args();
        delete $args{$field};
        like(dies { Net::Blossom::Response->new(%args) },
            qr/$field is required/, "$field required");
    }

    like(dies { Net::Blossom::Response->new(valid_response_args(), status => 99) },
        qr/status must be an HTTP status code/, 'low status rejected');
    like(dies { Net::Blossom::Response->new(valid_response_args(), headers => []) },
        qr/headers must be a hash reference/, 'headers hashref required');
    like(dies { Net::Blossom::Response->new(valid_response_args(), content => []) },
        qr/content must be a scalar/, 'content scalar required');
};

subtest 'Error validates required HTTP fields' => sub {
    my $error = Net::Blossom::Error->new(valid_error_args());
    is($error->status, 404, 'valid error constructed');

    for my $field (qw(method url status reason)) {
        my %args = valid_error_args();
        delete $args{$field};
        like(dies { Net::Blossom::Error->new(%args) },
            qr/$field is required/, "$field required");
    }

    like(dies { Net::Blossom::Error->new(valid_error_args(), status => 600) },
        qr/status must be an HTTP status code/, 'high status rejected');
    like(dies { Net::Blossom::Error->new(valid_error_args(), headers => []) },
        qr/headers must be a hash reference/, 'headers hashref required');
    like(dies { Net::Blossom::Error->new(valid_error_args(), body => []) },
        qr/body must be a scalar/, 'body scalar required');
    like(dies { Net::Blossom::Error->new(valid_error_args(), x_reason => []) },
        qr/x_reason must be a scalar/, 'x_reason scalar required');
};

subtest 'PaymentRequired validates HTTP fields and payment challenges' => sub {
    my $required = Net::Blossom::PaymentRequired->new(
        valid_error_args(),
        status             => 402,
        reason             => 'Payment Required',
        payment_challenges => { cashu => 'cashuA...' },
    );
    is($required->status, 402, 'valid payment required constructed');
    is_deeply([$required->payment_methods], ['cashu'], 'payment challenge preserved');

    for my $field (qw(method url status reason)) {
        my %args = (
            valid_error_args(),
            status             => 402,
            reason             => 'Payment Required',
            payment_challenges => { cashu => 'cashuA...' },
        );
        delete $args{$field};
        like(dies { Net::Blossom::PaymentRequired->new(%args) },
            qr/$field is required/, "$field required");
    }

    like(dies { Net::Blossom::PaymentRequired->new(valid_error_args(), status => 402, reason => 'Payment Required', payment_challenges => []) },
        qr/payment_challenges must be a hash reference/, 'payment challenges hashref required');
    like(dies { Net::Blossom::PaymentRequired->new(valid_error_args()) },
        qr/status must be 402 for PaymentRequired/, 'non-402 status rejected');
};

done_testing;
