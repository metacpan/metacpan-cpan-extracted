#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;
use Net::SharePoint::Basic;
my $sp = Net::SharePoint::Basic->new({max_log_size => 2});

$sp->log_it('test 1', 'doh');
isa_ok($sp->{log}, 'ARRAY');
is(scalar(@{$sp->{log}}), 1, 'log is of size 1');
like($sp->{log}[0][0], qr/^\d{10}$/, 'log timestamp ok');
is($sp->{log}[0][1], 'doh', 'severity ok');
is($sp->{log}[0][2], 'test 1', 'message ok');
$sp->log_it('test 2', 'bah');
is(scalar(@{$sp->{log}}), 2, 'log grew to 2');
like($sp->{log}[1][0], qr/^\d{10}$/, 'log timestamp ok');
is($sp->{log}[1][1], 'bah', 'severity ok');
is($sp->{log}[1][2], 'test 2', 'message ok');
$sp->log_it('test 3', 'boom');
is(scalar(@{$sp->{log}}), 2, 'log still is 2');
like($sp->{log}[0][0], qr/^\d{10}$/, 'log timestamp ok');
is($sp->{log}[0][1], 'bah', 'severity ok');
is($sp->{log}[0][2], 'test 2', 'message ok');
like($sp->{log}[1][0], qr/^\d{10}$/, 'log timestamp ok');
is($sp->{log}[1][1], 'boom', 'severity ok');
is($sp->{log}[1][2], 'test 3', 'message ok');
