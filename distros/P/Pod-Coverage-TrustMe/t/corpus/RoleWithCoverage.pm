package RoleWithCoverage;
use strict;
use warnings;

sub DOES {
  return 1 if $_[1] eq __PACKAGE__;
  return 0;
}

sub bar {
}

1;
__END__

=head2 bar

This is covered
