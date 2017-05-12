package A;
use Moose::Role;
sub items { qw/a a2/ }

package B;
use Moose::Role;
with 'A';
sub items { qw/b/ }

package C;
use Moose::Role;
sub items { qw/c/ }
sub multiply { shift; return map 2*$_, @_ }

package D;
use Moose;
sub items { qw/d/ }
sub multiply { shift; return map 3*$_, @_ }

package E;
use Moose;
extends 'D';
sub items { qw/e/ }

1;
