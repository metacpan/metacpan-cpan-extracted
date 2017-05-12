use strict;

use Test::More tests => 2;

use Set::Intersection;

use Data::Dumper;

# use of undef in key of hash is warning ??
my $warn = '';
local $SIG{__WARN__} = sub { $warn .= $_[0] };
eval { get_intersection([undef],[undef,undef]); };
#say STDERR "<$warn>";
like($warn,
    qr/Use of uninitialized value in list assignment/s,
    "Got expected warning of 'undef' in arrays provided as arguments"
);
ok !$@, "No error";


