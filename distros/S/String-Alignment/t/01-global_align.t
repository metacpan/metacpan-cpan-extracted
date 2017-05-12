use Test::More tests => 2;
use String::Alignment qw(do_alignment);

BEGIN {
my @result = split("\t",do_alignment("WRITERS", "VINTNER"));
is($result[0],"VINTNER-");
is($result[1],"WRIT-ERS");
}
