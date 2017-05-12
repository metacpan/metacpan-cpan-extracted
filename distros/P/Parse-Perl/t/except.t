use warnings;
use strict;

use Test::More tests => 6;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my $env = current_environment;

eval { parse_perl($env, "{") };
like $@, qr/\AMissing right /;

my $cv = eval { parse_perl($env, "main::wibble()") };
is $@, "";
eval { $cv->() };
like $@, qr/\AUndefined subroutine /;


$cv = eval { parse_perl($env, "die \"wibble\n\"") };
is $@, "";
eval { $cv->() };
is $@, "wibble\n";

1;
