
use strict;
use Test;

if( $ENV{SKIP_07} or not($ENV{HOSTNAME} =~ m/^corky/ and $ENV{TEST_AUTHOR}) ) {
    plan tests => 1;
    skip(1,0,1);
    exit;
}

plan tests => 1;

use Net::SMTP::OneLiner;

$Net::SMTP::OneLiner::PORT     = 997;
$Net::SMTP::OneLiner::HOSTNAME = "yhcat.mei.net";
$Net::SMTP::OneLiner::DEBUG    = 1;

send_mail( "jetero\@cpan.org", "jettero\@cpan.org", "test - " . time, "This is your test... #2", 'paul@mei.net');

ok 1;
