# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sendy-API.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 7;
BEGIN { use_ok('Net::Sendy::API') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

SKIP: {
    skip("SENDY_API_KEY and SENDY_URL variables are not set", 6) unless ($ENV{SENDY_API_KEY} && $ENV{SENDY_URL});

    my $sendy = Net::Sendy::API->new(api_key =>  $ENV{SENDY_API_KEY}, url => $ENV{SENDY_URL});
    ok($sendy);

    my $r = $sendy->subscribe(email => 'sherzodr@gmail.com',list => 'e');
    ok($r && $r->isa("HTTP::Response") && $r->is_success && $r->decoded_content eq '1');

    $r = $sendy->subscription_status(email => 'sherzodr@gmail.com', list => 'e');
    ok($r && $r->isa("HTTP::Response") && $r->is_success && $r->decoded_content eq 'Subscribed');

    $r = $sendy->active_subscriber_count( list => 'e' );
    ok($r && $r->isa("HTTP::Response") && $r->is_success && ($r->decoded_content == 1));

    $r = $sendy->unsubscribe(email => 'sherzodr@gmail.com', list => 'e');
    ok($r && $r->isa("HTTP::Response") && $r->is_success && $r->decoded_content eq '1');

    $r = $sendy->active_subscriber_count( list => 'e' );
    ok($r && $r->isa("HTTP::Response") && $r->is_success && ($r->decoded_content == 0));
}

