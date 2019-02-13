#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

use URI::Escape;

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new({config_file => 't/sharepoint.conf'});
my $payload = $sp->create_payload();

my $opts = $sp->{config};
is($payload, uri_escape(qq{grant_type=client_credentials&client_id=$opts->{sharepoint_client_id}\@$opts->{sharepoint_tenant_id}&client_secret=$opts->{sharepoint_client_secret}&resource=$opts->{sharepoint_principal_id}/$opts->{sharepoint_host}\@$opts->{sharepoint_tenant_id}&scope=$opts->{sharepoint_principal_id}/$opts->{sharepoint_host}\@$opts->{sharepoint_tenant_id}}, "^A-Za-z0-9\-\._~\&\="), 'payload ok');
