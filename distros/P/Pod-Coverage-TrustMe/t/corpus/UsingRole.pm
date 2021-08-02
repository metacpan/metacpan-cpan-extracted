package UsingRole;
use strict;
use warnings;

use SomeRole;

sub DOES {
  return 1 if $_[1] eq 'SomeRole';
  return 0;
}

sub bar { }

1;
__END__

=head1 SEE ALSO

L<SomeRole>
