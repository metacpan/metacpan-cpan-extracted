use v5.10;
use strict;
use warnings;

package Neo4j::Error::Usage;
# ABSTRACT: Neo4j exception thrown locally because of incorrect driver API use
$Neo4j::Error::Usage::VERSION = '0.01';

use parent 'Neo4j::Error';


sub source { 'Usage' }


1;
