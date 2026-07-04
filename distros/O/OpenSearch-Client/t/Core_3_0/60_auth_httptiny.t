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


use IO::Socket::SSL;
use lib 't/lib';

$ENV{OS_VERSION} = '3_0';
$ENV{OS_CXN} = 'HTTPTiny';
our $Throws_SSL = "SSL";

sub ssl_options {
    my $ca_file = $_[0];
    
    my $ssl_opts = ( $ca_file )
        ? { SSL_verify_mode => 0x01, SSL_verifycn_scheme => 'none', SSL_ca_file => $ca_file }
        : { SSL_verify_mode => 0x00 };
    
    return $ssl_opts;
}

do "os_sync_auth.pl" or die( $@ || $! );
