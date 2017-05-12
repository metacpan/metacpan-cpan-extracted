#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use SMS::ClickSend;
use Data::Dumper;

die 'env CLCIKSEND_USERNAME and CLICKSEND_APIKEY is required.'
    unless $ENV{CLCIKSEND_USERNAME} and $ENV{CLICKSEND_APIKEY};

my $sms = SMS::ClickSend->new(
    username => $ENV{CLCIKSEND_USERNAME},
    api_key  => $ENV{CLICKSEND_APIKEY}
);

my $res = $sms->send(
    to => '+61411111111',
    message => 'This is the message',
);
print Dumper(\$res);

# my $res = $sms->delivery('70A1EFA4-3F61-9D72-556C-D918FF3FC41');
# print Dumper(\$res);

# my $res = $sms->balance();
# print Dumper(\$res);

# my $res = $sms->history();
# print Dumper(\$res);

1;