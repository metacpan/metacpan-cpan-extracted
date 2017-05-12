use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok "Sub::Metadata", qw(sub_body_type); }

sub t0;
sub t1 { }

is sub_body_type(\&t0), "UNDEF";
is sub_body_type(\&t1), "PERL";
is sub_body_type(\&sub_body_type), "XSUB";

1;
