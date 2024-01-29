use 5.010;
use strict;
use warnings;

package Neo4j::Driver::StatementResult;
# ABSTRACT: DEPRECATED (renamed to Neo4j::Driver::Result)
$Neo4j::Driver::StatementResult::VERSION = '0.42';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::StatementResult - DEPRECATED (renamed to Neo4j::Driver::Result)

=head1 VERSION

version 0.42

=head1 SYNOPSIS

 package Neo4j::Driver::Result;
 use parent 'Neo4j::Driver::StatementResult';

=head1 DESCRIPTION

The Neo4j::Driver::StatementResult module was renamed to
L<Neo4j::Driver::Result> for version 0.19.

While the StatementResult module was part of the public API, that
module name was used only internally in the driver. Objects were
created by calling methods on session or transaction objects;
a C<new()> method was never publicly exposed for this module.
Therefore no issues due to this change are expected.

However, it is legal for clients to verify the type of result
objects using L<< isa()|UNIVERSAL/$obj->isa(-TYPE-) >>. To keep
such existing checks working for the time being, a module with
this name continues to be provided for use as a parent for
L<Neo4j::Driver::Result>.

B<Any use of C<Neo4j::Driver::StatementResult> is deprecated.>

This module will be removed in a future version of this driver.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Driver::B<Result>>

=item * Naming changes for the Neo4j Java driver 4.0:
L<neo4j/neo4j-java-driver#651|https://github.com/neo4j/neo4j-java-driver/pull/651>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://arne.johannessen.de/>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2023 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
