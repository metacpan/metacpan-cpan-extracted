# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use OpenSearch::Client;
use Test::More;
use strict;
use warnings;

my $trace
    = !$ENV{TRACE}       ? undef
    : $ENV{TRACE} eq '1' ? 'Stderr'
    :                      [ 'File', $ENV{TRACE} ];

unless ($ENV{CLIENT_VER}) {
    plan skip_all => 'No $ENV{CLIENT_VER} specified';
    exit;
}
unless ($ENV{OS}) {
    plan skip_all => 'No OpenSearch test node available';
    exit;
}

my $api       = "$ENV{CLIENT_VER}::Direct";
my $cxn       = $ENV{OS_CXN} || do "default_cxn.pl" || die( $@ || $! );
my $cxn_pool  = $ENV{OS_CXN_POOL} || 'Static';
my $timeout   = $ENV{OS_TIMEOUT} || 30;
my $userinfo  = $ENV{OS_USERINFO};
my $use_https = $ENV{OS_ALWAYS_SSL};
my @plugins  = split /,/, ( $ENV{OS_PLUGINS} || '' );
our %Auth;

if ( $userinfo && $use_https ) {
    %Auth = ( use_https => 1, userinfo => $userinfo );
}

my $es;
if ( $ENV{OS} ) {
    eval {
        $es = OpenSearch::Client->new(
            nodes            => $ENV{OS},
            trace_to         => $trace,
            cxn              => $cxn,
            cxn_pool         => $cxn_pool,
            client           => $api,
            request_timeout  => $timeout,
            plugins          => \@plugins,
            %Auth
        );
        $es->ping unless $ENV{OS_SKIP_PING};
        1;
    } || do {
        diag $@;
        undef $es;
    };
}

unless ( $ENV{OS_SKIP_PING} ) {
    my $version = $es->info->{version}{number};
    my $api     = $es->api_version;
    unless (substr( $api, 0, 1 ) eq substr( $version, 0, 1 ) )
    {
        plan skip_all =>
            "Tests are for API version $api but OpenSearch is version $version\n";
        exit;
    }
}

return $es;
