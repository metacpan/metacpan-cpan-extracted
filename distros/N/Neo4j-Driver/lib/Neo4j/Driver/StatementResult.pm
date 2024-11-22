use 5.010;
use strict;
use warnings;

package Neo4j::Driver::StatementResult;
# ABSTRACT: DEPRECATED (renamed to Neo4j::Driver::Result)
$Neo4j::Driver::StatementResult::VERSION = '0.52';

1;

__END__

The Neo4j::Driver::StatementResult module was renamed to
L<Neo4j::Driver::Result> for version 0.19.

While the StatementResult module was part of the public API, that
module name was used only internally in the driver. Objects were
created by calling methods on session or transaction objects;
a C<new()> method was never publicly exposed for this module.
Therefore no issues due to this change are expected.
