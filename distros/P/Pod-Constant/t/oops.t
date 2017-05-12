use strict;
use warnings;

# Declaring the value inside the X<> tag is wrong (it won't
# show up in the POD). We should detect and warn about this.

=head1 DESCRIPTION

Today's lucky number is X<$LUCKY=27>.

=cut

use Test::More tests => 1;
use Test::Exception;

throws_ok {
    require Pod::Constant;
    Pod::Constant->import('$LUCKY');
} qr/X<> tag should not include value/;

