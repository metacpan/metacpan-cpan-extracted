#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new();

isa_ok($sp, 'Net::SharePoint::Basic');
is_deeply($sp->{token}, {ts => 0}, 'token placeholder ok');
is($sp->{next_guid}, 1, 'next guid set');
is($sp->{config}{token_file}, $Net::SharePoint::Basic::DEFAULT_SHAREPOINT_TOKEN_FILE, 'default token file fallback');
is($sp->{config}{max_log_size}, $Net::SharePoint::Basic::MAX_LOG_SIZE, 'default max log size');
is($sp->{config}{chunk_size}, $Net::SharePoint::Basic::DEFAULT_CHUNK_SIZE, 'default chunk size');
is($sp->{config}{retries}, $Net::SharePoint::Basic::DEFAULT_RETRIES, 'default retries');
