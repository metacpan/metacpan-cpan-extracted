use strict;
use warnings;
use Test::More tests => 3;
use Net::APNS;

my $apns = Net::APNS->new;
isa_ok( $apns, 'Net::APNS' );
can_ok( $apns, qw/new notify/ );
my $notify = Net::APNS->notify({
    cert   => '',
    key    => '',
    passwd => '',
});
isa_ok( $notify, 'Net::APNS::Notification' );

1;

