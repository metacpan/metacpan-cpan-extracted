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

use Test::More;
use Test::Deep;
use Test::Exception;

use strict;
use warnings;
use lib 't/lib';

our $Throws_SSL;

unless ( $ENV{OS_SSL} ) {
    plan skip_all => "$ENV{OS_CXN} - No https server specified in OS_SSL";
    exit;
}

unless ( $ENV{OS_USERINFO} ) {
    plan skip_all => "$ENV{OS_CXN} - No user/pass specified in OS_USERINFO";
    exit;
}

unless ( $ENV{OS_CA_PATH} ) {
    plan skip_all => "$ENV{OS_CXN} - No cacert specified in OS_CA_PATH";
    exit;
}

$ENV{OS}           = $ENV{OS_SSL};
$ENV{OS_SKIP_PING} = 1;

our %Auth = ( use_https => 1, userinfo => $ENV{OS_USERINFO} );

# Test https connection with correct auth, without cacert
$ENV{OS_CXN_POOL} = 'Static';
$Auth{ssl_options} = ssl_options();

my $es = do "os_sync.pl" or die( $@ || $! );

ok $es->cluster->health,
    "$ENV{OS_CXN} - Non-cert HTTPS with auth, cxn static";

$ENV{OS_CXN_POOL} = 'Sniff';
$es = do "os_sync.pl" or die( $@ || $! );
ok $es->cluster->health, "$ENV{OS_CXN} - Non-cert HTTPS with auth, cxn sniff";

$ENV{OS_CXN_POOL} = 'Static::NoPing';
$es = do "os_sync.pl" or die( $@ || $! );
ok $es->cluster->health,
    "$ENV{OS_CXN} - Non-cert HTTPS with auth, cxn noping";

# Test https connection with correct auth, with valid cacert
$Auth{ssl_options} = ssl_options( $ENV{OS_CA_PATH} );

$es = do "os_sync.pl" or die( $@ || $! );

ok $es->cluster->health, "$ENV{OS_CXN} - Valid cert HTTPS with auth";

# Test invalid user credentials
%Auth = ( userinfo => 'foobar:baz' );

## HTTPTiny fails in a different way

if( $ENV{OS_CXN} eq 'HTTPTiny' ) {
    $es = do "os_sync.pl" or die( $@ || $! );
    throws_ok { $es->cluster->health }
    "OpenSearch::Client::Error::ContentLength",
        "$ENV{OS_CXN} - Bad userinfo";
} else {
    $es = do "os_sync.pl" or die( $@ || $! );
    throws_ok { $es->cluster->health }
    "OpenSearch::Client::Error::Cxn",
        "$ENV{OS_CXN} - Bad userinfo";
}

# Test https connection with correct auth, with invalid cacert
$Auth{ssl_options} = ssl_options('t/lib/bad_cacert.pem');
$ENV{OS}           = "https://www.google.com";

$es = do "os_sync.pl" or die( $@ || $! );

throws_ok { $es->cluster->health }
"OpenSearch::Client::Error::$Throws_SSL",
    "$ENV{OS_CXN} - Invalid cert throws $Throws_SSL";

done_testing;
