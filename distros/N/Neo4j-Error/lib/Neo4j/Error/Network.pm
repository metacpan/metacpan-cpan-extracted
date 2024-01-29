use v5.10;
use strict;
use warnings;

package Neo4j::Error::Network;
# ABSTRACT: Neo4j exception thrown because of a network protocol failure
$Neo4j::Error::Network::VERSION = '0.02';

use parent 'Neo4j::Error';


sub source { 'Network' }


sub is_retryable { !!1 }


1;
