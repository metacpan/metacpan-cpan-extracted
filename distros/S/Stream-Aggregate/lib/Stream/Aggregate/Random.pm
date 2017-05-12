
package Stream::Aggregate::Random;

use strict;
use warnings;
use Time::HiRes qw(time);

srand((time * 9327) ^ ($$ << 3) + (time % 8379));

1;

__END__

=head1 DESCRIPTION

Calls srand() with nice seed.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

