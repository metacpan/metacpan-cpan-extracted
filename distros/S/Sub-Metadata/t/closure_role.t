use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Sub::Metadata", qw(sub_closure_role); }

sub t0;
our $x;
sub t1 { $x }

is sub_closure_role(\&t0), "STANDALONE";
is sub_closure_role(\&t1), "STANDALONE";

our @a0;
sub MODIFY_CODE_ATTRIBUTES { push @a0, $_[1]; return () }
sub t2 { my $z = $_[0]; return sub :a0 { $x } }
sub t3 { my $z = $_[0]; return sub :a0 { $z } }

like sub_closure_role($a0[0]), qr/\A(?:STANDALONE|PROTOTYPE)\z/;
like sub_closure_role(t2(1)), qr/\A(?:STANDALONE|CLOSURE)\z/;
is sub_closure_role($a0[1]), "PROTOTYPE";
is sub_closure_role(t3(1)), "CLOSURE";

1;
