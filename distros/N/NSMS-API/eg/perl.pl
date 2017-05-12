#!/usr/bin/env perl

use strict;
use NSMS::API;

my $sms = NSMS::API->new(
    username => 'user',
    password => 'pass',
    debug    => 0
);

#$sms->to('1188220000');
#$sms->text('teste de sms');
print $sms->send( '118822000', 'teste de sms' );

