package Role::Time;

use strict;
use warnings;

use Simple::Accessor qw{date};

sub _build_date { '20210102' }

1;