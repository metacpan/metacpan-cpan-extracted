use 5.010;
use strict;
use warnings;

package Neo4j::Driver::Type::Temporal;
# ABSTRACT: DEPRECATED (use DateTime / Duration instead)
$Neo4j::Driver::Type::Temporal::VERSION = '0.45';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Type::Temporal - DEPRECATED (use DateTime / Duration instead)

=head1 VERSION

version 0.45

=head1 SYNOPSIS

 package Neo4j::Driver::Type::DateTime;
 use parent 'Neo4j::Driver::Type::Temporal';
 
 package Neo4j::Driver::Type::Duration;
 use parent 'Neo4j::Driver::Type::Temporal';

=head1 DESCRIPTION

The Neo4j::Driver::Type::Temporal module was created to
mark temporal values returned from the Neo4j server.
However, beyond that, it was never implemented, and the
documentation has always carried the warning:

E<nbsp> The package name C<Neo4j::Driver::Type::Temporal> may change
in future.

Since the L<Neo4j::Types> model doesn't have a shared super-type
for temporal instants and temporal durations, this module is
no longer required.

B<Any use of C<Neo4j::Driver::Type::Temporal> is deprecated.>

This module will be removed in a future version of this driver.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver::Types>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
