package Net::Drizzle::Result;
use strict;
use warnings;

# alias for dbi users
sub fetchrow_arrayref { shift->row_next(@_) }

1;
