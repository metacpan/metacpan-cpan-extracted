use strict;
use warnings;

use Test::More tests => 28;
use Test::Exception;

use constant METHODS => (
    'new', 'server', 'show', 'edit', 'login',
    'create', 'comment', 'correspond', 'merge_tickets', 'link_tickets',
    'unlink_tickets', 'search', 'get_attachment_ids', 'get_attachment',
    'get_transaction_ids', 'get_transaction', 'take', 'untake', 'steal',
    'timeout', 'basic_auth_cb',
);

use RT::Client::REST;

my $rt;

lives_ok {
    $rt = RT::Client::REST->new;
} 'RT::Client::REST instance created';

for my $method (METHODS) {
    can_ok($rt, $method);
}

throws_ok {
    $rt->login;
} 'RT::Client::REST::InvalidParameterValueException',
    "requires 'username' and 'password' parameters";

throws_ok {
    $rt->basic_auth_cb(1);
} 'RT::Client::REST::InvalidParameterValueException';

throws_ok {
    $rt->basic_auth_cb({});
} 'RT::Client::REST::InvalidParameterValueException';

lives_ok {
    $rt->basic_auth_cb(sub {});
};

{
    package BadLogger;
    sub new { bless \my $logger }
    for my $method (qw(debug me elmo)) {
        no strict 'refs';
        *$method = sub {
            my $self = shift;
            Test::More::diag("$method: @_\n");
        };
    }
}

throws_ok {
    RT::Client::REST->new(logger => BadLogger->new);
} 'RT::Client::REST::InvalidParameterValueException',
    'bad logger results in exception being thrown';

{
    package GoodLogger;
    sub new { bless \my $logger }
    for my $method (qw(debug info warn error)) {
        no strict 'refs';
        *$method = sub {
            my $self = shift;
            Test::More::diag("$method: @_\n");
        };
    }
}

lives_ok {
    RT::Client::REST->new(logger => GoodLogger->new);
} 'good logger, no exception thrown';

1;

# vim:ft=perl:
