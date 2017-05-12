#!/usr/bin/env perl
package Net::Journyx::Test;
use Moose;
extends 'Net::Journyx';

use Test::MockObject;

# and this wants to actually mock the
# XML server instead
has '+ua' => (
    default => sub {

        # the result object. change $Net::Journyx::Test::content to change the
        # results
        my $res = Test::MockObject->new;
        $res->set_bound(is_success   => \$content);
        $res->set_bound(content      => \$content);
        $res->set_bound(content_type => \$content_type);

        # the cookie object. the cookie name is hardcoded to JIFTY_SID
        my $cookie = Test::MockObject->new;
        $cookie->set_always(as_string => "JIFTY_SID=1010101");
        $cookie->set_true('set_cookie');

        my $mock = Test::MockObject->new;
        for (qw/get post head request/) {
            $mock->set_always($_ => $res);
        }
        $mock->set_always(cookie_jar => $cookie);

        $mock->set_isa('LWP::UserAgent');

        return $mock;
    },
);

# give the rest of the attributes defaults for brevity

has '+site' => (
    default => 'http://jifty.org',
);

has '+username' => (
    default => 'admin'
);

has '+password' => (
    default => 'password',
);

has '+wsdl' => (
    default => 'path/to/file.wsdl',
);

1;

