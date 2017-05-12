#!/usr/bin/env perl
package Net::Jifty::Test;
use Any::Moose;
extends 'Net::Jifty';

use Test::MockObject;

our $content_type = "text/x-yaml";
our $content = << "YAML";
---
fnord:
    success: 1

foo: 1
bar: 2
baz: 3

quux:
    - quuuux
    - quuuux

Atreides:
    - Leto: male
    - Jessica: female
    - Paul: male
    - Alia: female
YAML

has '+ua' => (
    default => sub {

        # the result object. change $Net::Jifty::Test::content to change the
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

has '+cookie_name' => (
    default => 'JIFTY_SID',
);

has '+appname' => (
    default => 'JiftyApp',
);

has '+email' => (
    default => 'user@host.tld',
);

has '+password' => (
    default => 'password',
);

# and override some methods
sub get_sid {
    shift->sid("deadbeef");
}


__PACKAGE__->meta->make_immutable;
no Any::Moose;


1;

