package CoveredByRole;
use strict;
use warnings;

use RoleWithCoverage;

sub DOES {
  return 1 if $_[1] eq 'RoleWithCoverage';
  return 0;
}

sub bar { }

1;
__END__

=head1 SEE ALSO

L<RoleWithCoverage>
