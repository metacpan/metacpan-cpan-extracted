# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/RAM/SessionGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::RAM::SessionGroup;

use strict;
no warnings 'deprecated';
use fields qw/dbh chatport _ego _hash/;

use OurNet::BBS::Base (
    '@packlist' => [ qw/pid uid msgs username from/ ],
);

sub STORE {
    my ($self, $key, $value) = @_;

    # XXX: SESSION STORE
}

1;
