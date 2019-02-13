#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Storable qw(dclone);

if (! $ENV{NET_SHAREPOINT_CONFIG}) {
        plan skip_all => 'SharePoint configuration is not defined';
        exit;
}
plan tests => 11;

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new({config_file => $ENV{NET_SHAREPOINT_CONFIG}});

my $payload = $sp->create_payload();
$sp->update_token();
is(  $sp->{token}{payload}, $payload,      'TOKEN payload correct');
is(  $sp->{token}{type},    'Bearer',      'TOKEN type correct');
like($sp->{token}{ts},      qr/^\d{10}$/,  'TOKEN ts a timestamp');
like($sp->{token}{token},   qr/^\S{1000}/, 'TOKEN itself looks correct');
sleep 2;
$sp->{token} = {ts => 0};
$sp->init_token();
is(  $sp->{token}{payload}, $payload,      'TOKEN payload correct');
is(  $sp->{token}{type},    'Bearer',      'TOKEN type correct');
like($sp->{token}{ts},      qr/^\d{10}$/,  'TOKEN ts a timestamp');
like($sp->{token}{token},   qr/^\S{1000}/, 'TOKEN itself looks correct');
ok(-f $sp->{config}{token_file}, 'token file exists');
cmp_ok(-M $sp->{config}{token_file}, '<', 100, 'and it is recent');

my $token = dclone $sp->{token};
$sp->init_token();
is_deeply($token, $sp->{token}, 'token unchanged');
