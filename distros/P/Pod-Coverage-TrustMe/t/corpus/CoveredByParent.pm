package CoveredByParent;
use strict;
use warnings;
use CoveredFile ();
BEGIN { our @ISA = qw(CoveredFile) }

sub covered_one {}
sub covered_two {}

1;
__END__

=head2 covered_one

Covered sub covered_one.

=head1 Parent

L<CoveredFile>
