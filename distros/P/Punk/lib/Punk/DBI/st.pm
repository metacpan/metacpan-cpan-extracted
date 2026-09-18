package Punk::DBI::st;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.51';
our @ISA = ('DBI::st');

# execute is C (include/punk/punk_dbiobs.h + xs/dbi.xs), installed into this
# package at load. This file is documentation.

1;

__END__

=head1 NAME

Punk::DBI::st - the observed statement handle

=head1 DESCRIPTION

The statement-handle half of L<Punk::DBI>: C<execute>, so a C<pk_abi> query
observer sees a statement the caller prepared and drove itself. This is the
path L<Punk::Model::DBI>'s generated methods take, through C<prepare_cached>.

The SQL comes from C<< $sth->{Statement} >> - what was prepared, placeholders
and all - and the bind B<count> from the argument list. The values are never
passed on.

C<prepare_cached> is unaffected: the subclass changes the class of the handle,
not its caching, and one statement handle per distinct SQL string is still what
a connection holds.

=head1 SEE ALSO

L<Punk::DBI>, L<Punk::DBI::db>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
