use strict;
use warnings;

use Pod::Knit;
use Test::Most;

like( 
    Pod::Knit->new( config => {} )
        ->munge_document( content => <<'END' ) ->as_pod => qr/=item \*/ );

=over

=item *

Foo

=back

END

done_testing;
