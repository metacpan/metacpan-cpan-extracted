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
use Test::Exception;
use OpenSearch::Client;

do './t/lib/LogCapture.pl' or die( $@ || $! );

isa_ok my $l = OpenSearch::Client->new->logger,
    'OpenSearch::Client::Logger::LogAny',
    'Logger';

test_level($_) for qw(debug info warning error critical trace);
test_throw($_) for qw(error critical);

done_testing;

#===================================
sub test_level {
#===================================
    my $level    = shift;
    my $levelf   = $level . 'f';
    my $is_level = 'is_' . $level;

    # ->debug
    ( $method, $messagetext ) = ();
    ok $l->$level("foo"), "$level";
    is $method, $level, "$level - method";
    is $messagetext, "foo", "$level - format";

    # ->debugf
    ( $method, $messagetext ) = ();
    ok $l->$levelf( "foo %s", "bar" ), "$levelf";
    is $method, $level, "$levelf - method";
    is $messagetext, "foo bar", "$levelf - format";
    
    ## ->is_debug - method is not reset here
    ## now using Capture
    ( $messagetext ) = ();
    ok $l->$is_level(), "$is_level";    
    is $method, $level, "$is_level - method";
    is $messagetext, undef, "$is_level - format";
}

#===================================
sub test_throw {
#===================================
    my $level = shift;
    my $throw = 'throw_' . $level;
    my $re    = qr/\[Request\] \*\* Foo/;
    ( $method, $messagetext ) = ();

    throws_ok { $l->$throw( 'Request', 'Foo', 42 ) } $re, $throw;

    is $@->{vars}, 42, "$throw - vars";
    is $method,   $level, "$throw - method";
    like $messagetext, $re,    "$throw - format";

}
